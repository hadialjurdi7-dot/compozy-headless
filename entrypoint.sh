#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/data}"
mkdir -p "$HOME/.compozy" /workspaces

CFG="$HOME/.compozy/config.toml"

if [ ! -f "$CFG" ]; then
    compozy install --provider "${COMPOZY_PROVIDER:-opencode}" -o json >/dev/null 2>&1 || true
fi

# Keep the daemon loopback-bound: that is the documented requirement for the HTTP API.
if ! grep -q '^\[http\]' "$CFG" 2>/dev/null; then
    printf '\n[http]\nhost = "localhost"\nport = %s\n' "${COMPOZY_HTTP_PORT:-2123}" >> "$CFG"
fi

# Optional OpenCode Go credential so the `opencode` ACP provider works without a manual login.
if [ -n "${OPENCODE_API_KEY:-}" ] && [ ! -f "$HOME/.local/share/opencode/auth.json" ]; then
    mkdir -p "$HOME/.local/share/opencode"
    printf '{"opencode-go":{"type":"api","key":"%s"}}' "$OPENCODE_API_KEY" \
        > "$HOME/.local/share/opencode/auth.json"
    chmod 600 "$HOME/.local/share/opencode/auth.json"
fi

nginx -c /etc/nginx/nginx.conf -g 'daemon off;' &

compozy daemon start --foreground &

wait -n
