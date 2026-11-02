#!/usr/bin/env bash
# Copy the firmware to the ESP32 and restart it.
#
#   ./deploy.sh [/dev/ttyUSB0]
#
# Requires mpremote (pipx install mpremote) and MicroPython already flashed.

set -euo pipefail

PORT="${1:-/dev/ttyUSB0}"
FILES=(config.py wifi.py sessions.py ring.py main.py)

if [[ ! -e "$PORT" ]]; then
  echo "error: $PORT not found. Is the board plugged in?" >&2
  exit 1
fi

if [[ ! -f config.py ]]; then
  echo "error: config.py missing. Copy config.example.py to config.py and fill it in." >&2
  exit 1
fi

for f in "${FILES[@]}"; do
  echo "  -> $f"
  mpremote connect "$PORT" cp "$f" ":$f"
done

echo "resetting..."
mpremote connect "$PORT" reset

cat <<'EOF'

Deployed. To see the device's IP address, attach to the REPL:

    mpremote connect /dev/ttyUSB0

Then press the board's RST button; it prints the listening URL on boot.
Put that address into hooks/settings.snippet.json and merge it into
~/.claude/settings.json.
EOF
