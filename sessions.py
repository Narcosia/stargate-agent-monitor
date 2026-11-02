"""Tracks the live state of every Claude Code session reporting to this device.

Only session_id and a state label are retained. Payload fields that carry
conversation content - user_input, last_assistant_message, message, cwd - are
deliberately never stored. See README, "What this device knows".
"""

import time

# Session states, in ascending order of "how much does this want your attention".
WORKING = "working"        # actively processing your turn
BACKGROUND = "background"  # foreground idle, but subagents/tasks still running
INPUT = "input"            # Stop fired: turn done, awaiting your next prompt
ATTENTION = "attention"    # permission prompt / explicitly needs input
DONE = "done"              # SessionEnd: lingers briefly, then disappears

# Ranked so the summary endpoint and any single-colour fallback can pick the
# most urgent state across all sessions.
URGENCY = {WORKING: 0, BACKGROUND: 0, DONE: 1, INPUT: 2, ATTENTION: 3}

# How long after the last background-work event a session keeps reading as
# BACKGROUND. This is a recency window rather than a counter because
# SubagentStart proved unreliable in practice - observed firing once against
# eleven SubagentStops - so matched pairs cannot be depended on. Any background
# event, start or stop, refreshes the window; a stream of them means work is
# ongoing. Overridden from config.
BACKGROUND_HOLD_MS = 90 * 1000


class Session:
    __slots__ = ("sid", "state", "order", "updated", "ended", "pending", "bg_until")

    def __init__(self, sid, order):
        self.sid = sid
        self.state = WORKING
        self.order = order
        self.updated = time.ticks_ms()
        self.ended = None
        # Outstanding background work, when the start/stop events happen to
        # pair up. Treated as corroboration, never as the sole signal.
        self.pending = 0
        # Deadline until which background work is assumed still running.
        self.bg_until = None

    def touch(self, state):
        self.state = state
        self.updated = time.ticks_ms()
        if state == DONE:
            self.ended = time.ticks_ms()
        else:
            self.ended = None

    def note_background(self, hold_ms):
        self.bg_until = time.ticks_add(time.ticks_ms(), hold_ms)

    def busy_in_background(self):
        if self.pending > 0:
            return True
        if self.bg_until is None:
            return False
        return time.ticks_diff(self.bg_until, time.ticks_ms()) > 0


def display_state(s):
    """The state to render, as opposed to the last event received.

    A session whose agents are still running has stopped emitting foreground
    events, which is indistinguishable from sitting idle - so it would show as
    'awaiting your input' when it wants nothing from you. BACKGROUND gives that
    its own colour rather than borrowing WORKING's, so 'chugging away without
    me' and 'actively on my turn' stay tellable apart.

    ATTENTION always wins: a permission prompt during background work is real
    and does block you. DONE is terminal and never reinterpreted.
    """
    if s.state in (ATTENTION, DONE):
        return s.state
    if s.busy_in_background():
        return BACKGROUND
    return s.state


class Registry:
    """Holds sessions, ordered by first-seen so their ring positions are stable.

    Expiry is state-dependent. A session in WORKING that has gone quiet is
    probably dead - a genuinely working session fires Stop eventually - so it
    gets a short TTL. A session in INPUT or ATTENTION may legitimately sit for
    days waiting on a human, and that is exactly the state worth displaying, so
    it gets a long one.

    A wrongly-pruned session is self-healing: update() registers unknown ids on
    arrival, so the next event from it puts its arc straight back. That makes an
    over-eager WORKING TTL cheap, and a stale arc from a crashed session the
    more expensive failure to avoid.
    """

    def __init__(self, ttl_ms, working_ttl_ms, done_linger_ms,
                 background_hold_ms=BACKGROUND_HOLD_MS):
        self._sessions = {}
        self._ttl = ttl_ms
        self._working_ttl = working_ttl_ms
        self._linger = done_linger_ms
        self._bg_hold = background_hold_ms
        self._counter = 0

    def _ttl_for(self, s):
        # Keyed on the raw state, not the displayed one: a session held at
        # 'working' only by a pending counter should still expire on the short
        # TTL if its background work never reports back.
        return self._working_ttl if s.state == WORKING else self._ttl

    def _get(self, sid):
        s = self._sessions.get(sid)
        if s is None:
            # An unknown session_id showing up mid-flight is normal: the device
            # may have rebooted, or hooks were added to an already-running
            # session. Register it rather than dropping the event.
            self._counter += 1
            s = Session(sid, self._counter)
            self._sessions[sid] = s
        return s

    def update(self, sid, state):
        s = self._get(sid)
        s.touch(state)
        return s

    def apply(self, sid, state, delta=0, reset_pending=False, background=False):
        """Record one event: a state change, a work delta, and/or a background ping.

        reset_pending is used on UserPromptSubmit. Both the counter and the
        recency window are re-baselined there: a new prompt means the previous
        turn's background work is over, which is also what stops the window
        from holding a session green after its agents have finished.
        """
        s = self._get(sid)
        if reset_pending:
            s.pending = 0
            s.bg_until = None
        if delta:
            s.pending = max(0, s.pending + delta)
        if background:
            s.note_background(self._bg_hold)
        if state is not None:
            s.touch(state)
        else:
            # A background ping is activity even with no state transition;
            # without this the session could age out mid-background-run.
            s.updated = time.ticks_ms()
        return s

    def remove(self, sid):
        self._sessions.pop(sid, None)

    def prune(self):
        """Drop expired sessions and finished ones past their linger window."""
        now = time.ticks_ms()
        for sid in list(self._sessions.keys()):
            s = self._sessions[sid]
            if s.state == DONE and s.ended is not None:
                if time.ticks_diff(now, s.ended) > self._linger:
                    del self._sessions[sid]
                continue
            if time.ticks_diff(now, s.updated) > self._ttl_for(s):
                del self._sessions[sid]

    def active(self):
        """Sessions in stable display order."""
        return sorted(self._sessions.values(), key=lambda s: s.order)

    def count(self):
        return len(self._sessions)

    def most_urgent(self):
        top = None
        for s in self._sessions.values():
            if top is None or URGENCY[display_state(s)] > URGENCY[display_state(top)]:
                top = s
        return top

    def clear(self):
        self._sessions.clear()

    def summary(self):
        now = time.ticks_ms()
        out = []
        for s in self.active():
            age = time.ticks_diff(now, s.updated)
            out.append({
                "session": s.sid[:8],
                "state": display_state(s),
                "raw_state": s.state,
                "pending": s.pending,
                "background": s.busy_in_background(),
                "age_ms": age,
                # Makes it obvious from /status why an arc is about to vanish.
                "expires_in_ms": max(0, self._ttl_for(s) - age),
            })
        return out
