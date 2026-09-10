#!/bin/sh
# Railway entrypoint: generate ~/.aurix/config.yaml from env vars,
# because gateway config (telegram token, etc.) is only read from
# the config file, not from environment variables.
set -e

CONFIG_DIR="$HOME/.aurix"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

mkdir -p "$CONFIG_DIR"

# Only auto-generate if user didn't mount/provide their own config
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" <<EOF
provider: "${AURIX_PROVIDER:-openai}"
baseUrl: "${AURIX_BASE_URL:-}"
apiKey: "${AURIX_API_KEY:-}"
model: "${AURIX_MODEL:-gpt-4o}"
researchMode: "${AURIX_RESEARCH_MODE:-low}"

gateway:
  telegram:
    enabled: true
    token: "${TELEGRAM_TOKEN:-}"
EOF
  echo "[entrypoint] generated $CONFIG_FILE from env vars"
else
  echo "[entrypoint] using existing $CONFIG_FILE"
fi

# Disable the auto-started local Reddit relay (binds localhost only,
# useless on Railway and may clash with \$PORT)
export AURIX_REDDIT_BACKEND="${AURIX_REDDIT_BACKEND:-off}"

# Bun is aurix's preferred runtime (avoids node:ffi issues); fall back to node
if command -v bun >/dev/null 2>&1; then
  echo "[entrypoint] starting gateway with bun"
  exec bun dist/index.js gateway
else
  echo "[entrypoint] bun not found, starting gateway with node"
  exec node dist/index.js gateway
fi
