"""Copy to config.py and fill in. config.py is gitignored - never commit credentials."""

# --- WiFi -------------------------------------------------------------------
WIFI_SSID = "your-network"
WIFI_PASS = "your-password"

# Static IP keeps the hook URL stable across reboots. Set to None for DHCP,
# but then the address may change and you'd have to edit settings.json again.
# Format: (ip, subnet, gateway, dns)
STATIC_IP = None
# STATIC_IP = ("192.168.1.50", "255.255.255.0", "192.168.1.1", "192.168.1.1")

HOSTNAME = "claude-ring"

# --- Hardware ---------------------------------------------------------------
LED_PIN = 13    # GPIO wired to the ring's Din
LED_COUNT = 24  # XC4385 has 24

# Peak brightness, 0-255. 24 WS2812Bs at full white draw ~1.4 A - far past what
# USB supplies. 24 keeps the whole ring near ~150 mA at peak. Raise only with a
# dedicated 5 V supply sharing ground with the ESP32.
BRIGHTNESS = 24

# --- Server -----------------------------------------------------------------
PORT = 80

# Optional shared secret. If set, requests must carry `X-Ring-Token: <value>`.
# Configure the matching header in settings.json. See README on why this is
# only a light guard, not real security.
TOKEN = None

# Drop a session if nothing is heard from it for this long. Guards against
# sessions that die without firing SessionEnd. Generous, because a session
# legitimately sitting awaiting your input sends no events.
SESSION_TTL_MS = 4 * 60 * 60 * 1000  # 4 hours, for idle/attention sessions

# Shorter expiry for sessions still marked 'working'. A working session that has
# gone quiet this long has almost certainly died without firing SessionEnd
# (terminal closed, SSH dropped, crash). Pruning is safe: any later event from
# that session re-registers it immediately, so a wrong guess self-heals.
# Raise it if you routinely run turns longer than this.
WORKING_TTL_MS = 60 * 60 * 1000  # 1 hour

# How long a finished session stays green before disappearing.
DONE_LINGER_MS = 5000

# How long after the last background-work event a session keeps showing green.
# A recency window rather than a counter: SubagentStart fires unreliably, so
# matched start/stop pairs cannot be trusted. Any background event refreshes it.
BACKGROUND_HOLD_MS = 90 * 1000  # 90 seconds

# Colour theme: "classic" (blue/green/amber/red), "neon" (cyan/green/hot pink/red),
# or "vapor" (all pink and cyan - prettier, less legible). A dict of per-state
# (r, g, b) also works and is merged over classic, so you can override one state:
#   THEME = {"input": (255, 0, 200)}
THEME = "vapor"
