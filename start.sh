#!/usr/bin/env bash
# Mongez — one-shot launcher.
#
# Usage:
#   ./start.sh                    # build (if needed), start, wait healthy, print info
#   ./start.sh --rebuild          # force a clean image rebuild
#   ./start.sh --seed             # also create test accounts (client1/worker1/admin1)
#   ./start.sh --mobile           # also `flutter run` the mobile app afterwards
#   ./start.sh --logs             # follow `docker compose logs` after starting
#   ./start.sh --stop             # stop the stack (keep volumes)
#   ./start.sh --down             # stop + wipe volumes (DESTROYS DB and uploads)
#   ./start.sh --status           # show container + health status and exit
#
# Flags can be combined, e.g.  ./start.sh --rebuild --seed --logs

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"
COMPOSE_SERVICE="web"
CONTAINER_NAME="mongez-backend"
HEALTH_URL="http://localhost:8000/api/health/"
WORKERS_URL="http://localhost:8000/api/workers/"
ADMIN_URL="http://localhost:8000/admin/"

# ── Colors (no-op when not a TTY) ────────────────────────────────────────────
if [ -t 1 ]; then
  C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'; C_ERR=$'\033[1;31m'
  C_DIM=$'\033[2m';   C_HL=$'\033[1;36m';  C_RST=$'\033[0m'
else
  C_OK=''; C_WARN=''; C_ERR=''; C_DIM=''; C_HL=''; C_RST=''
fi

step()  { printf "%s→%s %s\n" "$C_HL"  "$C_RST" "$*"; }
ok()    { printf "%s✓%s %s\n" "$C_OK"  "$C_RST" "$*"; }
warn()  { printf "%s!%s %s\n" "$C_WARN" "$C_RST" "$*"; }
fail()  { printf "%s✗%s %s\n" "$C_ERR" "$C_RST" "$*" >&2; }
die()   { fail "$*"; exit 1; }

# ── Flag parsing ─────────────────────────────────────────────────────────────
DO_REBUILD=0
DO_SEED=0
DO_MOBILE=0
DO_LOGS=0
DO_STOP=0
DO_DOWN=0
DO_STATUS=0

for arg in "$@"; do
  case "$arg" in
    --rebuild) DO_REBUILD=1 ;;
    --seed)    DO_SEED=1    ;;
    --mobile)  DO_MOBILE=1  ;;
    --logs)    DO_LOGS=1    ;;
    --stop)    DO_STOP=1    ;;
    --down)    DO_DOWN=1    ;;
    --status)  DO_STATUS=1  ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *)
      die "Unknown flag: $arg  (try --help)"
      ;;
  esac
done

# ── Prereqs ──────────────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH"
docker compose version >/dev/null 2>&1 || die "docker compose plugin is required"

# ── Lifecycle shortcuts that exit early ──────────────────────────────────────
if [ "$DO_STATUS" = 1 ]; then
  docker compose ps
  exit 0
fi
if [ "$DO_STOP" = 1 ]; then
  step "Stopping stack (volumes preserved)..."
  docker compose down
  ok "Stopped."
  exit 0
fi
if [ "$DO_DOWN" = 1 ]; then
  printf "%sThis will DELETE the database and uploaded files.%s\n" "$C_WARN" "$C_RST"
  read -r -p "Type 'yes' to confirm: " ans
  [ "$ans" = "yes" ] || { warn "Aborted."; exit 1; }
  docker compose down -v
  ok "Stopped and wiped."
  exit 0
fi

# ── .env bootstrap ───────────────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$ENV_EXAMPLE" ]; then
    step "Creating $ENV_FILE from $ENV_EXAMPLE..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    # Generate a real SECRET_KEY so the default doesn't ship.
    if command -v python3 >/dev/null 2>&1; then
      key="$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')"
      # sed -i differs between GNU and BSD; this form works on both via tmp file.
      tmp="$(mktemp)"
      awk -v k="$key" '/^DJANGO_SECRET_KEY=/{print "DJANGO_SECRET_KEY=" k; next} {print}' "$ENV_FILE" > "$tmp"
      mv "$tmp" "$ENV_FILE"
      ok "Generated a fresh DJANGO_SECRET_KEY in $ENV_FILE"
    else
      warn "python3 not found — edit DJANGO_SECRET_KEY in $ENV_FILE manually."
    fi
  else
    die "Neither $ENV_FILE nor $ENV_EXAMPLE found."
  fi
fi

# ── Build (only if image missing, or --rebuild) ──────────────────────────────
need_build=0
if [ "$DO_REBUILD" = 1 ]; then
  need_build=1
elif ! docker image inspect mongez-backend:latest >/dev/null 2>&1; then
  need_build=1
fi

if [ "$need_build" = 1 ]; then
  step "Building image (mongez-backend:latest)..."
  if [ "$DO_REBUILD" = 1 ]; then
    docker compose build --no-cache "$COMPOSE_SERVICE"
  else
    docker compose build "$COMPOSE_SERVICE"
  fi
  ok "Image built."
else
  ok "Image already present — skipping build (use --rebuild to force)."
fi

# ── Start ────────────────────────────────────────────────────────────────────
step "Starting container..."
docker compose up -d "$COMPOSE_SERVICE" >/dev/null
ok "Container started."

# ── Wait for healthcheck ─────────────────────────────────────────────────────
step "Waiting for healthcheck to go green..."
deadline=$(( $(date +%s) + 90 ))
last=""
while :; do
  status="$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo missing)"
  if [ "$status" != "$last" ]; then
    printf "  %s[%s]%s health=%s\n" "$C_DIM" "$(date +%H:%M:%S)" "$C_RST" "$status"
    last="$status"
  fi
  case "$status" in
    healthy) ok "Healthy."; break ;;
    unhealthy)
      fail "Container is unhealthy. Last 50 log lines:"
      docker compose logs --tail=50 "$COMPOSE_SERVICE"
      exit 1
      ;;
  esac
  if [ "$(date +%s)" -ge "$deadline" ]; then
    fail "Timed out waiting for healthy status. Recent logs:"
    docker compose logs --tail=50 "$COMPOSE_SERVICE"
    exit 1
  fi
  sleep 2
done

# ── Confirm API reachable from host ──────────────────────────────────────────
if curl --silent --fail "$HEALTH_URL" >/dev/null; then
  ok "API responding at $HEALTH_URL"
else
  warn "Container is healthy but $HEALTH_URL is unreachable from the host. Check port mapping."
fi

# ── Optional: seed test accounts ─────────────────────────────────────────────
if [ "$DO_SEED" = 1 ]; then
  step "Seeding test accounts (client1 / worker1 / admin1)..."
  docker compose exec -T "$COMPOSE_SERVICE" python manage.py shell <<'PY'
from apps.users.models import User
accounts = [
    {"username":"client1","phone":"01000000001","email":"client1@mongez.local","password":"ClientPass123","role":User.Role.CLIENT,"name_ar":"عميل تجريبي"},
    {"username":"worker1","phone":"01000000002","email":"worker1@mongez.local","password":"WorkerPass123","role":User.Role.WORKER,"name_ar":"عامل تجريبي"},
    {"username":"admin1", "phone":"01000000003","email":"admin1@mongez.local", "password":"AdminPass123", "role":User.Role.ADMIN, "name_ar":"مشرف تجريبي"},
]
for a in accounts:
    u,created = User.objects.get_or_create(username=a["username"],
        defaults={"phone":a["phone"],"email":a["email"],"role":a["role"],"name_ar":a["name_ar"]})
    u.phone=a["phone"]; u.email=a["email"]; u.role=a["role"]; u.name_ar=a["name_ar"]
    u.set_password(a["password"])
    if a["role"]==User.Role.ADMIN: u.is_staff=True; u.is_superuser=True
    u.save()
    print(f"  {'created' if created else 'updated'}: {u.username} (role={u.role})")
PY
  ok "Seed complete."
fi

# ── Summary ──────────────────────────────────────────────────────────────────
printf "\n%s================ Mongez is up ================%s\n" "$C_HL" "$C_RST"
printf "  API:     %shttp://localhost:8000/api/%s\n"      "$C_OK" "$C_RST"
printf "  Health:  %s%s%s\n"                              "$C_OK" "$HEALTH_URL" "$C_RST"
printf "  Workers: %s%s%s\n"                              "$C_OK" "$WORKERS_URL" "$C_RST"
printf "  Admin:   %s%s%s\n"                              "$C_OK" "$ADMIN_URL"   "$C_RST"
if [ "$DO_SEED" = 1 ]; then
  printf "\n  Test accounts:\n"
  printf "    client : %sclient1 / ClientPass123%s\n" "$C_OK" "$C_RST"
  printf "    worker : %sworker1 / WorkerPass123%s\n" "$C_OK" "$C_RST"
  printf "    admin  : %sadmin1  / AdminPass123%s\n"  "$C_OK" "$C_RST"
fi
printf "%s===============================================%s\n" "$C_HL" "$C_RST"
printf "%sNotes:%s\n" "$C_DIM" "$C_RST"
printf "  • Stop:        ./start.sh --stop\n"
printf "  • Wipe data:   ./start.sh --down\n"
printf "  • Rebuild:     ./start.sh --rebuild\n"
printf "  • Logs:        docker compose logs -f web\n"
printf "  • Android emu: change mobile baseUrl to http://10.0.2.2:8000/api/\n\n"

# ── Optional: launch mobile ──────────────────────────────────────────────────
if [ "$DO_MOBILE" = 1 ]; then
  if ! command -v flutter >/dev/null 2>&1; then
    warn "flutter not on PATH — skipping --mobile."
  elif [ ! -d mobile ]; then
    warn "mobile/ directory not found — skipping --mobile."
  else
    step "Fetching Flutter packages..."
    ( cd mobile && flutter pub get )
    step "Launching mobile app (flutter run)..."
    ( cd mobile && flutter run )
  fi
fi

# ── Optional: follow logs ────────────────────────────────────────────────────
if [ "$DO_LOGS" = 1 ]; then
  step "Following backend logs (Ctrl+C to detach — container keeps running)..."
  exec docker compose logs -f "$COMPOSE_SERVICE"
fi
