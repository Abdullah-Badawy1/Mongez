#!/bin/sh
# Container entrypoint:
#   1. (root) Ensure /app/data and /app/media exist and are writable by `app`.
#      This matters because Docker mounts named volumes as root by default.
#   2. (app)  Apply pending migrations and exec Gunicorn.
#
# `exec gosu app …` replaces the shell so Gunicorn is PID 1's child and
# receives SIGTERM directly from Docker on graceful shutdown.
set -e

mkdir -p /app/data /app/media
chown -R app:app /app/data /app/media

echo "→ Applying database migrations…"
gosu app python manage.py migrate --noinput

# Optional: hot-reload Python on file changes when RELOAD=1 (dev mode).
RELOAD_FLAG=""
if [ "${RELOAD:-0}" = "1" ]; then
    RELOAD_FLAG="--reload"
    echo "→ Gunicorn will run with --reload (dev mode)"
fi

echo "→ Starting Gunicorn on :8000"
exec gosu app gunicorn core.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers "${GUNICORN_WORKERS:-2}" \
    --timeout "${GUNICORN_TIMEOUT:-120}" \
    ${RELOAD_FLAG} \
    --access-logfile - \
    --error-logfile -
