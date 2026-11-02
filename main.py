"""Claude Code status ring.

Receives Claude Code hook events over HTTP and shows the state of every live
session on a WS2812B ring.

Endpoints
  POST /hook    hook payload from Claude Code (`"type": "http"` hook)
  GET  /        status as JSON
  GET  /health  bare liveness check
  POST /clear   forget all sessions

Responses to /hook are always 200 with an EMPTY body. A 2xx with a text body
would be fed back into the session as added context - not something a status
light should ever do.
"""

import asyncio
import json
import time

import config
import sessions as S
import wifi
from ring import Ring

FRAME_MS = 30       # ~33 fps
PRUNE_EVERY = 100   # frames between expiry sweeps

registry = S.Registry(
    config.SESSION_TTL_MS,
    getattr(config, "WORKING_TTL_MS", config.SESSION_TTL_MS),
    config.DONE_LINGER_MS,
    getattr(config, "BACKGROUND_HOLD_MS", S.BACKGROUND_HOLD_MS),
)
ring = Ring(config.LED_PIN, config.LED_COUNT, config.BRIGHTNESS,
            getattr(config, "THEME", "vapor"))

# Notification subtypes that genuinely block on a human. Red is reserved for
# these. Note that idle_prompt is NOT here: it means "this session has been
# quiet a while", which is exactly what a session waiting on background agents
# looks like. Treating it as blocking made the ring cry wolf, so it maps to
# INPUT instead - and even that is suppressed while background work is pending.
_ATTENTION_NOTIFICATIONS = (
    "permission_prompt",
    "agent_needs_input",
    "elicitation_dialog",
)

# Events that start a unit of background work, and those that end one.
_WORK_START = ("SubagentStart", "TaskCreated")
_WORK_END = ("SubagentStop", "TaskCompleted")


# Recent events, newest last, for diagnosing why an arc is the colour it is.
# Metadata only - event name, notification subtype, truncated session id. No
# payload content, consistent with the rest of the device.
_EVENTS = []
_EVENTS_MAX = 40


def record_event(sid, event, kind, state, pending):
    _EVENTS.append({
        "t": time.ticks_ms(),
        "session": sid[:8],
        "event": event,
        "kind": kind,
        "state": state,
        "pending": pending,
    })
    if len(_EVENTS) > _EVENTS_MAX:
        del _EVENTS[0]


def classify(payload):
    """Map a hook payload to (state, pending_delta, reset_pending, background).

    state is None to leave the session's state alone - used by the background
    work events, which only mark the session as busy elsewhere.

    `background` refreshes the recency window. Both starts AND stops set it,
    because SubagentStart cannot be relied on: observed in the field firing
    once against eleven SubagentStops. A stream of stops is itself evidence
    that agents are running, so any background event counts.
    """
    event = payload.get("hook_event_name")

    if event in ("UserPromptSubmit", "SessionStart"):
        # A new prompt re-baselines the counter and the window; see
        # Registry.apply. This is also what releases a session from BACKGROUND
        # once its agents are genuinely finished.
        return S.WORKING, 0, True, False
    if event == "Stop":
        return S.INPUT, 0, False, False
    if event == "SessionEnd":
        return S.DONE, 0, False, False

    if event in _WORK_START:
        return None, 1, False, True
    if event in _WORK_END:
        return None, -1, False, True

    if event == "Notification":
        kind = payload.get("notification_type", "")
        if kind in _ATTENTION_NOTIFICATIONS:
            return S.ATTENTION, 0, False, False
        if kind in ("idle_prompt", "agent_completed"):
            return S.INPUT, 0, False, False
        # auth_success, elicitation_complete, etc. carry no status meaning.
        return None, 0, False, False

    return None, 0, False, False


async def handle(reader, writer):
    try:
        line = await asyncio.wait_for(reader.readline(), 5)
        if not line:
            return
        parts = line.decode().split()
        if len(parts) < 2:
            await respond(writer, 400)
            return
        method, path = parts[0], parts[1]

        length = 0
        token = None
        while True:
            hdr = await asyncio.wait_for(reader.readline(), 5)
            if not hdr or hdr == b"\r\n":
                break
            low = hdr.lower()
            if low.startswith(b"content-length:"):
                try:
                    length = int(hdr.split(b":", 1)[1].strip())
                except ValueError:
                    length = 0
            elif low.startswith(b"x-ring-token:"):
                token = hdr.split(b":", 1)[1].strip().decode()

        body = b""
        if length:
            # Cap the read: a status light has no reason to accept large bodies,
            # and an unbounded readexactly is a trivial way to exhaust RAM.
            body = await asyncio.wait_for(reader.readexactly(min(length, 8192)), 5)

        if config.TOKEN and token != config.TOKEN:
            await respond(writer, 401)
            return

        if path.startswith("/hook") and method == "POST":
            await route_hook(writer, body)
        elif path.startswith("/health"):
            await respond(writer, 200, "ok", "text/plain")
        elif path.startswith("/events"):
            await respond(writer, 200, json.dumps(_EVENTS), "application/json")
        elif path.startswith("/clear") and method == "POST":
            registry.clear()
            del _EVENTS[:]
            await respond(writer, 200, "cleared", "text/plain")
        elif path == "/" or path.startswith("/status"):
            await respond(writer, 200, json.dumps({
                "sessions": registry.summary(),
                "count": registry.count(),
                "uptime_ms": time.ticks_ms(),
            }), "application/json")
        else:
            await respond(writer, 404)
    except asyncio.TimeoutError:
        pass
    except Exception as e:  # never let one bad request kill the server
        print("http error:", e)
    finally:
        try:
            await writer.wait_closed()
        except Exception:
            pass


async def route_hook(writer, body):
    try:
        payload = json.loads(body) if body else {}
        sid = payload.get("session_id")
        state, delta, reset, background = classify(payload)
    except (ValueError, AttributeError) as e:
        print("hook: bad payload:", e)
        # Still a 200: a malformed body is our problem, not the session's, and
        # a non-2xx would log an error in every Claude Code turn.
        await respond(writer, 200)
        return

    if sid and (state is not None or delta or reset or background):
        s = registry.apply(sid, state, delta, reset, background)
        event = payload.get("hook_event_name")
        kind = payload.get("notification_type")
        kind = kind or payload.get("stop_reason")
        record_event(sid, event, kind, S.display_state(s), s.pending)
        print("hook:", event, kind or "", sid[:8], "->",
              S.display_state(s), "pending=%d" % s.pending)

    await respond(writer, 200)


async def respond(writer, status, body="", ctype="text/plain"):
    reason = {200: "OK", 400: "Bad Request", 401: "Unauthorized",
              404: "Not Found"}.get(status, "OK")
    payload = body.encode() if isinstance(body, str) else body
    writer.write(
        b"HTTP/1.1 %d %s\r\nContent-Type: %s\r\nContent-Length: %d\r\n"
        b"Connection: close\r\n\r\n"
        % (status, reason, ctype.encode(), len(payload))
    )
    if payload:
        writer.write(payload)
    await writer.drain()
    writer.close()


async def animate():
    phase = 0
    frames = 0
    while True:
        ring.render(registry, phase, config.DONE_LINGER_MS)
        phase = (phase + 1) & 0x7FFF
        frames += 1
        if frames >= PRUNE_EVERY:
            frames = 0
            registry.prune()
        await asyncio.sleep_ms(FRAME_MS)


async def watch_wifi(wlan):
    while True:
        await asyncio.sleep(30)
        wifi.ensure(wlan, config.WIFI_SSID, config.WIFI_PASS)


async def main():
    wlan = wifi.connect(
        config.WIFI_SSID, config.WIFI_PASS,
        getattr(config, "STATIC_IP", None),
        getattr(config, "HOSTNAME", None),
    )
    ip = wlan.ifconfig()[0]
    print("ring: listening on http://%s:%d/hook" % (ip, config.PORT))

    await asyncio.start_server(handle, "0.0.0.0", config.PORT)
    await asyncio.gather(animate(), watch_wifi(wlan))


try:
    asyncio.run(main())
except KeyboardInterrupt:
    ring.clear()
    print("stopped, ring cleared")
