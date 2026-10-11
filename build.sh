#!/usr/bin/env bash
# Build and start everything for the demo: Postgres, database, web app, backend, demo data.
# Usage: ./build.sh [--no-web]   (--no-web skips the Flutter build and reuses mobile/build/web)
# Safe to re-run: steps that are already done are skipped. Ctrl+C stops the backend.
set -euo pipefail
cd "$(dirname "$0")"

PGDATA="$HOME/pgdata"
PGPORT=3000
APP_URL="http://localhost:3001"
export PATH="$HOME/development/flutter/bin:$HOME/.cargo/bin:$PATH"

step() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }

step "Postgres (port $PGPORT)"
if pg_isready -q -h "$PGDATA" -p "$PGPORT"; then
  echo "already running"
else
  pg_ctl -D "$PGDATA" -o "-p $PGPORT -k $PGDATA" -l "$PGDATA/server.log" -w start
fi

step "Database (migrations run when the backend starts)"
sqlx database create   # reads DATABASE_URL from .env; does nothing if the database exists

if [[ "${1:-}" != "--no-web" ]]; then
  step "Web app (Flutter)"
  (cd mobile && flutter build web --release --no-web-resources-cdn)
fi

step "Backend"
cargo build -p coffeelog-backend
if pgrep -x coffeelog-backe >/dev/null; then
  echo "Stopping the backend that is already running"
  pkill -x coffeelog-backe
  sleep 1
fi
./target/debug/coffeelog-backend &
BACKEND_PID=$!
trap 'kill $BACKEND_PID 2>/dev/null' EXIT INT TERM

for _ in $(seq 60); do
  curl -sf -o /dev/null "$APP_URL" && break
  sleep 0.5
done

step "Demo data"
node scripts/seed-demo.mjs "$APP_URL"

step "Ready: $APP_URL  (demo/demo1234 or nordlys/demo1234). Ctrl+C to stop."
wait $BACKEND_PID
