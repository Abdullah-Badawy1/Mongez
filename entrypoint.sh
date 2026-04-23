#!/bin/sh
set -e

mkdir -p /app/data /app/media

python manage.py migrate --noinput
exec gunicorn core.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --timeout 120
