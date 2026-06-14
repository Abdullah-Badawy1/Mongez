# syntax=docker/dockerfile:1.6
# Mongez backend — Django REST API
#
# The image runs Gunicorn as an unprivileged `app` user (uid 1000), but the
# entrypoint runs briefly as root so it can fix volume permissions on first
# boot. `gosu` then drops privileges before exec'ing Gunicorn.

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Runtime libs:
#   libjpeg62-turbo zlib1g — Pillow JPEG/PNG decoding (avatars)
#   curl                   — used by HEALTHCHECK
#   gosu                   — drop privileges in the entrypoint
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libjpeg62-turbo \
        zlib1g \
        curl \
        gosu \
    && rm -rf /var/lib/apt/lists/*

# Create the runtime user up-front; entrypoint chowns mounted volumes to it.
RUN useradd --system --uid 1000 --home /app --shell /usr/sbin/nologin app

# Install Python deps first so the layer caches independently of source code.
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy source after deps so code edits don't bust the wheel cache.
COPY . .

# Pre-collect static for the admin and DRF browsable API.
RUN DJANGO_SECRET_KEY=build-time-key \
    DJANGO_DEBUG=false \
    python manage.py collectstatic --noinput

RUN chmod +x /app/entrypoint.sh \
    && mkdir -p /app/data /app/media \
    && chown -R app:app /app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl --fail --silent http://127.0.0.1:8000/api/health/ || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
