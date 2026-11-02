#!/usr/bin/env bash
# Merge the status-ring hooks into ~/.claude/settings.json on this machine.
#
#   ./install-hooks.sh [ring-ip]        # default: 192.168.1.200
#   ./install-hooks.sh --remove         # take them out again
#
# Safe to re-run: replaces only this ring's hooks, leaves everything else alone.
# Writes a timestamped backup before touching anything.

set -euo pipefail

SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
# Foreground state events, plus background-work events so the ring can tell
# "waiting on you" from "waiting on its own agents".
EVENTS=(SessionStart UserPromptSubmit Notification Stop SessionEnd
        SubagentStart SubagentStop TaskCreated TaskCompleted)

# Background-work events fire far more often than the rest. A shorter timeout
# bounds the worst case when the ring is powered off but its IP still routes.
FAST_EVENTS="SubagentStart SubagentStop TaskCreated TaskCompleted"

if [[ "${1:-}" == "--remove" ]]; then
  MODE=remove; IP=""
else
  MODE=install; IP="${1:-192.168.1.200}"
fi

command -v python3 >/dev/null || { echo "error: python3 required" >&2; exit 1; }
mkdir -p "$(dirname "$SETTINGS")"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

python3 - "$SETTINGS" "$MODE" "$IP" "$FAST_EVENTS" "${EVENTS[@]}" <<'PY'
import json, shutil, sys, time

path, mode, ip, fast, *events = sys.argv[1:]
fast_events = set(fast.split())

try:
    with open(path) as f:
        settings = json.load(f)
except json.JSONDecodeError as e:
    sys.exit(f"error: {path} is not valid JSON ({e}).\n"
             "Fix it first - a malformed settings.json silently disables ALL settings in it.")

backup = f"{path}.bak-{time.strftime('%Y%m%d-%H%M%S')}"
shutil.copy2(path, backup)

hooks = settings.setdefault("hooks", {})
url = f"http://{ip}/hook" if ip else None
changed = []

def is_ring_hook(h):
    """A ring hook is any http hook whose URL path is /hook - matches this
    device at its current OR a previous address, so re-running with a new IP
    replaces the old entry instead of stacking a duplicate."""
    return h.get("type") == "http" and str(h.get("url", "")).endswith("/hook")

for event in events:
    groups = hooks.get(event, [])
    # Strip any existing ring hooks, keeping every other hook untouched.
    for group in groups:
        before = len(group.get("hooks", []))
        group["hooks"] = [h for h in group.get("hooks", []) if not is_ring_hook(h)]
        if len(group["hooks"]) != before:
            changed.append(f"removed from {event}")
    groups = [g for g in groups if g.get("hooks")]

    if mode == "install":
        timeout = 2 if event in fast_events else 5
        groups.append({"hooks": [{"type": "http", "url": url, "timeout": timeout}]})
        changed.append(f"added to {event}")

    if groups:
        hooks[event] = groups
    else:
        hooks.pop(event, None)

if not hooks:
    settings.pop("hooks", None)

with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print(f"backup: {backup}")
for c in changed:
    print(f"  {c}")
print(f"\n{'installed' if mode == 'install' else 'removed'}: {path}")
if mode == "install":
    print(f"ring url: {url}")
PY

echo
echo "Verify the ring can be reached from this machine:"
echo "    curl -s http://${IP:-192.168.1.200}/health"
