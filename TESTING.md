# Testing Mongez — Step by Step

A single doc that takes the platform from a fresh clone to *"I verified
every layer works"*. Each step has a **command**, an **expected result**,
and a **what-it-proves** note. Follow top-to-bottom on first run; jump
to a section when you only want to recheck one layer.

> Linux / macOS commands shown. Windows equivalents in
> [`WINDOWS.md`](WINDOWS.md) §7 ("Linux→PowerShell command map").

---

## 0. Prerequisites (one-time)

| Tool | Min version | Used by |
|---|---|---|
| Docker + Docker Compose v2 | 24+ | Backend test step |
| Python 3.11+ (host) | — | Optional, for `manage.py check` outside Docker |
| Node.js LTS | 18+ | Dashboard lint / build / dev |
| Flutter SDK | 3.10+ | Mobile analyze / test / run |
| curl | any | Manual API smoke tests |

Sanity check the toolchain:

```bash
docker --version
docker compose version
node -v
npm -v
flutter --version
```

---

## 1. The 30-second "everything is up" smoke test

```bash
./start.sh --rebuild --seed --dashboard
```

**Expected output (tail):**

```
✓ Healthy.
✓ API responding at http://localhost:8000/api/health/
✓ Dashboard responding at http://localhost:5173/

================ Mongez is up ================
  API:       http://localhost:8000/api/
  Dashboard: http://localhost:5173/
```

**What it proves:** Docker image builds, migrations apply, Gunicorn
boots, the React dev server compiles, and the three test accounts
(`client1` / `worker1` / `admin1`, all `*Pass123`) exist.

Stop everything when you're done:

```bash
./start.sh --stop
```

---

## 2. Backend — Django REST API

### 2.1 Start the backend only

```bash
./start.sh
```

Expected: `✓ Healthy.` then `✓ API responding at http://localhost:8000/api/health/`.

### 2.2 System checks (config sanity)

```bash
docker compose exec -T web python manage.py check
docker compose exec -T web python manage.py makemigrations --dry-run
```

**Expected:**

```
System check identified no issues (0 silenced).
No changes detected
```

**What it proves:** every Django app loads, every URL resolves, every
model field matches a migration. If `makemigrations --dry-run` lists
operations, models changed and a migration is missing.

### 2.3 Unit + integration tests

```bash
docker compose exec -T web python manage.py test apps --noinput
```

> Use `apps` (the namespace label), not bare `test`. Bare discovery
> double-imports models as both `apps.X` and `core.apps.X` and crashes —
> known repo layout quirk.

**Expected (current count):**

```
Ran 39 tests in ~5s
OK
```

Per-app:

```bash
docker compose exec -T web python manage.py test apps.users
docker compose exec -T web python manage.py test apps.workers
docker compose exec -T web python manage.py test apps.orders
docker compose exec -T web python manage.py test apps.ratings
docker compose exec -T web python manage.py test apps.favorites
docker compose exec -T web python manage.py test apps.notifications
docker compose exec -T web python manage.py test apps.payments
docker compose exec -T web python manage.py test apps.admin_api
```

**What it proves:** each app's model logic, serializers, views, and
permission gates work end-to-end against a fresh in-memory SQLite.

### 2.4 Manual API smoke tests with `curl`

Run these against the live container — fast, no client setup.

```bash
# Health
curl -s http://localhost:8000/api/health/
# → {"status": "ok"}

# Public endpoint (no auth needed)
curl -s http://localhost:8000/api/workers/ | head -c 200

# Login (use --seed accounts; see §1)
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login/ \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin1","password":"AdminPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')
echo "got token: ${TOKEN:0:20}..."

# Protected endpoint (the admin dashboard aggregate)
curl -s http://localhost:8000/api/admin/dashboard/ \
  -H "Authorization: Bearer $TOKEN" | head -c 200
# → {"stats":{"total_users":3,...

# Negative test: same endpoint as a non-admin
CLIENT_TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login/ \
  -H 'Content-Type: application/json' \
  -d '{"username":"client1","password":"ClientPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  http://localhost:8000/api/admin/dashboard/ \
  -H "Authorization: Bearer $CLIENT_TOKEN"
# → HTTP 403
```

**What it proves:** auth, role gating, JSON shape, and CORS at runtime —
the bits unit tests can't see.

### 2.5 Live logs

```bash
docker compose logs -f web              # backend access + error log
```

---

## 3. Dashboard — React + Vite (`front/`)

### 3.1 One-time install

```bash
cd front
cp .env.example .env       # if you haven't already
npm install
```

### 3.2 Lint

```bash
npm run lint
```

**Expected:** no output / exit 0 (== 0 errors, 0 warnings).

### 3.3 Production build

```bash
npm run build
```

**Expected:**

```
✓ 870 modules transformed.
dist/index.html        ...
dist/assets/index-*.js ~562 kB
✓ built in ~2s
```

**What it proves:** every import resolves, the bundle compiles, and the
output is deployable (Firebase, S3, nginx, whatever).

### 3.4 Dev server (manual UI test)

```bash
npm run dev
# → Local: http://localhost:5173/
```

Open <http://localhost:5173/>. Manual checklist (5 minutes):

| Step | What you should see |
|---|---|
| Landing renders | Hero, Services, How it works, Why choose, App promo, Footer |
| Toggle language (top right) | Page flips between Arabic (RTL) and English (LTR) |
| Click **Login** | `/login` form |
| Login as `admin1` / `AdminPass123` | Redirect to `/admin` |
| Admin dashboard | StatsCards populated, "Recent orders" table renders |
| Sidebar → **Users** | List with `admin1`, `client1`, `worker1` and `?role=` filter works |
| Sidebar → **Workers** | List with the seeded worker profile (or empty if none yet) |
| Logout | Returns to `/login`, refresh keeps you logged out |
| Login as `client1` | `/admin/*` should redirect or 403 — non-admin gate works |

(The dev server proxies `/api` and `/media` to `localhost:8000` — start
the backend first if it isn't already.)

---

## 4. Mobile — Flutter (`mobile/`)

### 4.1 One-time install

```bash
cd mobile
flutter pub get
```

### 4.2 Static analysis

```bash
flutter analyze
```

**Expected:** 0 errors, 0 warnings. (Today's repo has ~28 `info`-level
style hints — those are fine; only `error` / `warning` matter.)

### 4.3 Unit / widget tests

```bash
flutter test
```

**Expected:**

```
00:01 +N: All tests passed!
```

### 4.4 Run the app against the live backend

Pick a target and adjust the API base URL accordingly:

| Target | `mobile/lib/core/constants/api_constants.dart` baseUrl |
|---|---|
| Linux desktop / iOS sim / web | `http://127.0.0.1:8000/api/` |
| Android emulator | `http://10.0.2.2:8000/api/` |
| Physical phone on Wi-Fi | `http://<your-LAN-IP>:8000/api/` (also add to `DJANGO_ALLOWED_HOSTS`) |

```bash
flutter run -d linux     # desktop
flutter run -d chrome    # browser (web build)
flutter run              # asks which device
```

Manual checklist:

| Step | What you should see |
|---|---|
| App boots | Splash → onboarding (first run) or login (later runs) |
| Register a new client | Account created, JWT stored, lands on Home |
| Browse categories / workers | Lists populate from `/api/categories/` and `/api/workers/` |
| Place an order | POST `/api/orders/` succeeds, appears under "My requests" |
| Login as `worker1` | Sees the same order under "Incoming" / "Technician requests" |
| Accept → Complete the order | Status moves through ACCEPTED → COMPLETED |
| Client rates the worker | POST `/api/ratings/` succeeds, worker's `average_rating` updates |

---

## 5. End-to-end integration test (full stack, by hand)

This is the *"everything talks to everything"* test. ~10 minutes.

1. **Start the stack**

   ```bash
   ./start.sh --rebuild --seed --dashboard
   ```

2. **Confirm three surfaces are alive**

   * <http://localhost:8000/api/health/> → `{"status":"ok"}`
   * <http://localhost:8000/admin/> → 404 (Django admin removed by design)
   * <http://localhost:5173/> → marketing landing page

3. **Run automated backend tests** (§2.3) — must be `OK`.
4. **Run dashboard lint + build** (§3.2, §3.3) — both clean.
5. **Run Flutter analyze + test** (§4.2, §4.3) — both clean.

6. **Run a real user flow end to end** in a browser:
   * Open <http://localhost:5173/login>, log in as `client1`.
     *(Sign-up via the SPA only lands on the public landing — login
     route is what hooks into the JWT pair.)*
   * (Currently the SPA only ships the **admin** flow; client/worker
     flows happen in the mobile app — that's by design.)
   * Open <http://localhost:5173/admin> as `admin1`. Verify
     the stats count includes the seeded users.

7. **Place an order on mobile, observe it from the dashboard:**
   * Mobile → log in as `client1` → place a service order.
   * Dashboard → log in as `admin1` → `/admin/orders` → the new
     order is in the list.
   * Dashboard → PATCH the order's status to `ACCEPTED` (or use the
     UI). The mobile app's polling cubit picks it up within ~30 s.

8. **Stop the stack**

   ```bash
   ./start.sh --stop
   ```

If steps 1–8 all pass, every component — Docker, Django, the React
SPA, the Flutter app, JWT, Paymob hooks, and the notification fan-out —
is wired correctly.

---

## 6. Live data sync — exercise the cross-client refresh

There's no WebSocket layer; both surfaces poll. This script proves the
**dashboard ↔ mobile** loop end-to-end against `./start.sh --seed`.

```bash
ADMIN=$(curl -s -X POST localhost:8000/api/auth/login/ -H 'Content-Type: application/json' \
  -d '{"username":"admin1","password":"AdminPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')
CLIENT=$(curl -s -X POST localhost:8000/api/auth/login/ -H 'Content-Type: application/json' \
  -d '{"username":"client1","password":"ClientPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')
CAT=$(curl -s localhost:8000/api/categories/ | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')

# 1. Mobile-side action — client places an order
OID=$(curl -s -X POST localhost:8000/api/orders/ -H "Authorization: Bearer $CLIENT" \
  -F "service_category=$CAT" -F "description=sync probe" -F "urgency=NORMAL" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
echo "client placed order #$OID (status PENDING)"

# 2. Dashboard-side action — admin flips status
curl -s -X PATCH "localhost:8000/api/admin/orders/$OID/status/" \
  -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' \
  -d '{"status":"ACCEPTED"}' >/dev/null

# 3. Mobile re-poll (CustomerOrdersCubit's 30 s loop hits this)
STATUS=$(curl -s localhost:8000/api/orders/ -H "Authorization: Bearer $CLIENT" \
  | python3 -c "import sys,json,os; d=json.load(sys.stdin); it=d if isinstance(d,list) else d.get('results',[]); o=next(x for x in it if x['id']==int(os.environ['OID'])); print(o['status'])" OID=$OID)
echo "  → /api/orders/        status now = $STATUS"

# 4. Mobile notification poll (NotificationCubit's 30 s loop hits this)
N=$(curl -s localhost:8000/api/notifications/ -H "Authorization: Bearer $CLIENT" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); it=d if isinstance(d,list) else d.get("results",[]); print(len(it))')
echo "  → /api/notifications/ row count = $N (was 0 before admin acted)"
```

Expected:

```
client placed order #XX (status PENDING)
  → /api/orders/        status now = ACCEPTED
  → /api/notifications/ row count = 1   (or more if other tests ran first)
```

**What it proves:** the dashboard PATCH on `/admin/orders/<id>/status/`
triggers two writes (order row + Notification rows for the client and
the worker) so the mobile sees the change via both its order-list cubit
poll AND its notification cubit poll. If FCM is configured a push fires
too.

Browser-side check — open `/admin/orders` in two browser tabs, change a
status in one. The other tab's row should flip within 10 s without
manual refresh, and the "Updated X s ago" badge in the corner ticks up.

---

## 7. CI (what GitHub Actions runs on every push)

The workflow at `.github/workflows/` runs roughly the same backend
suite headlessly. To replicate locally:

```bash
docker compose -f docker-compose.yml run --rm web python manage.py test apps
```

If this passes on your machine, CI will pass too (modulo environment
differences caught by step §2.4 manual probes).

---

## 8. Troubleshooting test failures

| Symptom | Likely cause | Fix |
|---|---|---|
| `Model class … doesn't declare an explicit app_label` | You ran bare `python manage.py test` instead of `test apps` | Use `manage.py test apps` (§2.3) |
| `Ports are not available: bind :8000` | Old container or another process holds the port | `./start.sh --stop`, then `lsof -i :8000` (Linux) / `netstat -ano \| findstr :8000` (Windows) |
| Dashboard says "Network Error" | Backend not running, or wrong proxy target | Confirm `curl http://localhost:8000/api/health/` works; restart `npm run dev` |
| `flutter test` errors with `package:mongez/...` not found | Forgot `flutter pub get` | Re-run inside `mobile/` |
| Container stuck `health=starting` | Migration crashed mid-boot | `docker compose logs web --tail=80`, look for the traceback |
| Tests pass but `curl /api/health/` 502 | Gunicorn workers crashed | `docker compose logs web` — usually a config / import error introduced since last build |

---

## 9. Cheat sheet — copy/paste block

```bash
# everything, from scratch
./start.sh --rebuild --seed --dashboard

# automated
docker compose exec -T web python manage.py test apps        # backend
( cd front  && npm run lint && npm run build )                # dashboard
( cd mobile && flutter analyze && flutter test )              # mobile

# clean up
./start.sh --stop                                             # stop, keep data
./start.sh --down                                             # stop, WIPE data
```
