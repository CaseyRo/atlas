#!/bin/bash
set -euo pipefail

LOGFILE="/config/logs/boot.log"
mkdir -p /config/logs

log() {
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$TIMESTAMP 🔹 $1" | tee -a "$LOGFILE"
}

ATLAS_UI_PORT="${ATLAS_UI_PORT:-8888}"
ATLAS_API_PORT="${ATLAS_API_PORT:-8889}"
export ATLAS_UI_PORT ATLAS_API_PORT

TEMPLATE="/config/nginx/default.conf.template"
if [[ -f "$TEMPLATE" ]]; then
  log "🧩 Rendering Nginx config (UI port: $ATLAS_UI_PORT, API port: $ATLAS_API_PORT)"
  envsubst '${ATLAS_UI_PORT} ${ATLAS_API_PORT}' < "$TEMPLATE" > /etc/nginx/conf.d/default.conf
fi

# Start FastAPI in the background
log "🚀 Starting FastAPI backend on port $ATLAS_API_PORT..."
export PYTHONPATH=/config
uvicorn scripts.app:app --host 0.0.0.0 --port "$ATLAS_API_PORT" > /config/logs/uvicorn.log 2>&1 &

# Start Nginx in the foreground — this keeps the container alive
log "🌐 Starting Nginx server on port $ATLAS_UI_PORT..."
nginx -g "daemon off;" &

NGINX_PID=$!

# Run scans in background
(
  log "📦 Initializing database..."
  /config/bin/atlas initdb && log "✅ Database initialized."

  log "🚀 Running fast scan..."
  /config/bin/atlas fastscan && log "✅ Fast scan complete."

  log "🐳 Running Docker scan..."
  /config/bin/atlas dockerscan && log "✅ Docker scan complete."

  log "🕵️ Running deep host scan..."
  /config/bin/atlas deepscan && log "✅ Deep scan complete."
) &

wait "$NGINX_PID"
