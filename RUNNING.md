# Running Mongez — Step by Step

The one place to look up *"how do I bring this up?"*. Linear, copy-paste
friendly. Linux/macOS commands shown; Windows equivalents in
[`WINDOWS.md`](WINDOWS.md).

There are **three runtime surfaces**:

| # | Surface | Where | Default URL |
|---|---|---|---|
| 1 | Backend (Django REST API in Docker) | `core/` + `docker-compose.yml` | <http://localhost:8000/api/> |
| 2 | Dashboard (React + Vite SPA — landing + admin) | `front/` | <http://localhost:5173/> |
| 3 | Mobile (Flutter) | `mobile/` | flutter device window |

If a port is already taken, Vite will pick the next free one (5174, 5175…) — the launcher detects this and prints the actual URL.

---

## 0. One-time setup (~10 min)

```bash
# Clone (if you don't already have it)
git clone https://github.com/Abdullah-Badawy1/Mongez.git
cd Mongez

# Tools you need on PATH
docker --version          # 24+
docker compose version    # v2+
node -v                   # 18+
flutter --version         # 3.10+   (only for mobile)

# Backend .env
cp .env.example .env      # the launcher does this for you on first run too

# Dashboard .env
cp front/.env.example front/.env
```

That's it. Everything else is `./start.sh`.

---

## 1. Fastest path — bring up everything in one command

```bash
./start.sh --rebuild --seed --dashboard
```

What happens:

1. Builds the Docker image (`mongez-backend:latest`) from scratch.
2. Starts the container, waits for the `/api/health/` healthcheck to go green.
3. Seeds three test accounts: `client1`, `worker1`, `admin1` (all `*Pass123`).
4. Runs `npm install` in `front/` (idempotent — instant after the first time).
5. Starts Vite dev server in the background, writes its PID to `.dashboard.pid` and its log to `.dashboard.log`.

You'll see this when it's done:

```
================ Mongez is up ================
  API:       http://localhost:8000/api/health/
  Workers:   http://localhost:8000/api/workers/
  Dashboard: http://localhost:5173/

  Test accounts:
    client : client1 / ClientPass123
    worker : worker1 / WorkerPass123
    admin  : admin1  / AdminPass123
```

Open the dashboard, log in with `admin1` / `AdminPass123` → you land on `/admin`.

To stop everything:

```bash
./start.sh --stop
```

To stop **and** wipe the database + uploads:

```bash
./start.sh --down
```

---

## 2. Surface-by-surface (when you only want one)

### 2.1 Backend only

```bash
./start.sh
# or, raw Docker:
docker compose up -d --build web
docker compose logs -f web        # tail logs
```

Verify it's alive:

```bash
curl http://localhost:8000/api/health/      # → {"status": "ok"}
curl http://localhost:8000/api/workers/     # public, returns paginated list
```

There is **no Django admin** — the backend is a pure REST API. All
management happens via the React dashboard's `/admin/*` routes
(§2.2), which hit the `/api/admin/*` endpoints under
`apps.admin_api`.

### 2.2 Dashboard only (Vite dev server)

The dashboard needs the backend running first (otherwise `/api/*` proxies fail).

```bash
cd front
npm install                       # one-time
npm run dev
# → Local: http://localhost:5173/
```

Visit:

| URL | What you should see |
|---|---|
| <http://localhost:5173/> | Landing page (Hero, Services, How it works, Why choose, App promo, Footer) |
| Top-right language toggle | Page flips between Arabic (RTL) and English (LTR) |
| <http://localhost:5173/login> | Login form — sign in as `admin1` / `AdminPass123` |
| <http://localhost:5173/admin> | Stats cards + recent orders table |
| <http://localhost:5173/admin/users> | Paginated user list with `?role=` filter |
| <http://localhost:5173/admin/workers> | Worker profiles with computed score |
| <http://localhost:5173/admin/categories> | Service categories |
| <http://localhost:5173/admin/orders> | Order list (admin can PATCH status) |
| <http://localhost:5173/admin/payments> | Paymob commission rows |
| <http://localhost:5173/admin/ratings> | All ratings |

Production build (deployable static bundle):

```bash
npm run build           # → front/dist/
firebase deploy --only hosting       # ships dist/ to Firebase Hosting
```

### 2.3 Mobile only

```bash
cd mobile
flutter pub get
flutter run -d linux                 # Linux desktop
flutter run -d chrome                # web preview
flutter run                          # asks which device
```

Pick the right base URL for your target — edit
`mobile/lib/core/constants/api_constants.dart`:

| Target | `baseUrl` |
|---|---|
| Linux desktop / iOS sim / web | `http://127.0.0.1:8000/api/` |
| Android emulator | `http://10.0.2.2:8000/api/` |
| Physical Android on Wi-Fi | `http://<your-LAN-IP>:8000/api/` (also add the IP to `DJANGO_ALLOWED_HOSTS` in `.env`) |

---

## 3. Combo flags reference (`start.sh`)

| Command | Effect |
|---|---|
| `./start.sh` | Backend only, reuse cached image |
| `./start.sh --rebuild` | Force `docker build --no-cache` |
| `./start.sh --seed` | Backend + seed 3 test accounts |
| `./start.sh --dashboard` | Backend + dashboard dev server (background) |
| `./start.sh --mobile` | Backend + `flutter run` (foreground, blocks) |
| `./start.sh --all` | `= --seed --dashboard --mobile` (full local stack) |
| `./start.sh --logs` | After start, tail backend logs |
| `./start.sh --status` | `docker compose ps` and exit |
| `./start.sh --stop` | Stop backend **and** dashboard |
| `./start.sh --down` | Stop **and wipe** database/uploads |

Combine freely: `./start.sh --rebuild --seed --dashboard --logs`.

Windows uses `start.ps1` with the same flags as PowerShell switches
(`-Rebuild -Seed -Dashboard -All -Stop -Down -Status -FollowLogs`). See
[`WINDOWS.md`](WINDOWS.md).

---

## 4. The 60-second "did it actually work?" probe

Run this block after `./start.sh --seed --dashboard`. Everything should
print without errors.

```bash
# 1. Backend health
curl -s http://localhost:8000/api/health/

# 2. Dashboard SPA shell loads
curl -s -o /dev/null -w "/        → HTTP %{http_code}\n" http://localhost:5173/
curl -s -o /dev/null -w "/login   → HTTP %{http_code}\n" http://localhost:5173/login
curl -s -o /dev/null -w "/admin → HTTP %{http_code}\n" http://localhost:5173/admin

# 3. End-to-end auth + admin endpoint (through the dev-server proxy,
#    so this is exactly what the browser does)
TOKEN=$(curl -s -X POST http://localhost:5173/api/auth/login/ \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin1","password":"AdminPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')

# Admin dashboard data
curl -s http://localhost:5173/api/admin/dashboard/ \
  -H "Authorization: Bearer $TOKEN" | head -c 250 && echo

# Admin users list (role-filtered)
curl -s "http://localhost:5173/api/admin/users/?role=client" \
  -H "Authorization: Bearer $TOKEN" | head -c 200 && echo

# Non-admin token gets 403 (role gate)
CTOK=$(curl -s -X POST http://localhost:5173/api/auth/login/ \
  -H 'Content-Type: application/json' \
  -d '{"username":"client1","password":"ClientPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')
curl -s -o /dev/null -w "client → /admin/dashboard = HTTP %{http_code}\n" \
  http://localhost:5173/api/admin/dashboard/ \
  -H "Authorization: Bearer $CTOK"   # → 403
```

Expected tail:

```
{"status": "ok"}
/        → HTTP 200
/login   → HTTP 200
/admin/dashboard → HTTP 200
{"stats":{"total_users":3,...
{"count":1,"page":1,"page_size":20,...
client → /admin/dashboard = HTTP 403
```

If all six lines look like that, the **landing page + admin page work
seamlessly with the backend** — same code path the browser takes.

---

## 5. Live data sync — how the dashboard and mobile stay fresh

There is no WebSocket layer. Both surfaces poll the same REST API on a
per-page cadence; a tiny `usePolling` hook (front) and `Timer.periodic`
(mobile) gate their fetches on visibility so an idle tab / backgrounded
app stops hitting the API. Every page also shows an
**"Updated X s ago"** badge with a manual refresh button.

### 5.1 Dashboard → backend

Each admin page polls on its own interval (chosen to match how dynamic
the underlying data is) and pauses when the browser tab is hidden:

| Page | Interval | Why |
|---|---|---|
| Dashboard | 10 s | primary "is the system breathing" surface |
| Orders | 10 s | most dynamic — mobile-placed orders land fast |
| Payments | 15 s | Paymob webhooks land out-of-band |
| Workers | 30 s | profile changes are slow |
| Users | 30 s | admin rarely watches the list move |
| Ratings | 30 s | only fires on order-complete |
| Categories | 60 s | basically static; parallel-admin safety net |

* **Optimistic update** — `/admin/orders` flips a row's status in local
  state the moment the admin clicks the dropdown, then PATCHes
  `/api/admin/orders/<id>/status/`. If the PATCH fails the change is
  reverted.
* **Backend cache** — `/api/admin/dashboard/` caches its aggregate in
  Django's cache for **5 s**, so N admins polling at 10 s each still
  cost at most one DB query every other tick. Recent-orders stays
  uncached because the serializer's URLs are per-request.

### 5.2 Mobile → backend

Three cubits run a 30 s `Timer.periodic` while a relevant screen is
mounted:

| Cubit | Screen | Endpoint |
|---|---|---|
| `NotificationCubit` | (global, started after login) | `GET /api/notifications/` |
| `CustomerOrdersCubit` | "My requests" (client) | `GET /api/orders/` |
| `TechnicianOrdersCubit` | "Incoming" / "Requests" (worker) | `GET /api/orders/` |

A failed poll keeps the cached state on screen instead of flashing an
error.

### 5.3 Backend → mobile (when the admin acts)

When an admin PATCHes an order status from the dashboard,
`apps.admin_api.views.AdminOrderStatusView` fans the change out:

* Writes a `Notification` row for the client.
* Writes a `Notification` row for the assigned worker (if any).
* Sends FCM push to both (best-effort; silent if `FCM_SERVER_KEY` is
  unset).

So the mobile sees an admin action through **two independent channels**
— the order-list cubit picks up the new `status`, and the notification
cubit picks up the new bell — plus instant FCM push when configured.
No-op PATCHes (same status sent twice) don't fan out.

End-to-end proof — copy/paste against a `--seed`'d stack:

```bash
ADMIN=$(curl -s -X POST localhost:8000/api/auth/login/ -H 'Content-Type: application/json' \
  -d '{"username":"admin1","password":"AdminPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')
CLIENT=$(curl -s -X POST localhost:8000/api/auth/login/ -H 'Content-Type: application/json' \
  -d '{"username":"client1","password":"ClientPass123"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["tokens"]["access"])')
CAT=$(curl -s localhost:8000/api/categories/ | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')

# Client places an order — status PENDING
OID=$(curl -s -X POST localhost:8000/api/orders/ -H "Authorization: Bearer $CLIENT" \
  -F "service_category=$CAT" -F "description=demo" -F "urgency=NORMAL" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

# Admin flips it to ACCEPTED from the dashboard
curl -s -X PATCH "localhost:8000/api/admin/orders/$OID/status/" \
  -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' \
  -d '{"status":"ACCEPTED"}'

# Mobile picks up the new status and bell within 30 s — same endpoints the
# CustomerOrdersCubit and NotificationCubit hit:
curl -s localhost:8000/api/orders/ -H "Authorization: Bearer $CLIENT" | head -c 200
curl -s localhost:8000/api/notifications/ -H "Authorization: Bearer $CLIENT" | head -c 200
```

---

## 6. Common quick recipes

### Reset everything to a clean state

```bash
./start.sh --down               # stops + wipes volumes (asks for "yes")
./start.sh --rebuild --seed --dashboard
```

### Just restart after a code change

```bash
# Backend Python change — Docker has the code mounted via the image, so:
./start.sh --rebuild
# Dashboard React change — Vite HMR picks it up automatically; nothing to do.
# Mobile Dart change — Flutter hot reload (press `r` in the run terminal).
```

### Tail logs

```bash
docker compose logs -f web       # backend
tail -f .dashboard.log           # dashboard (Vite)
```

### Open a Django shell against the live container

```bash
docker compose exec web python manage.py shell
```

### Run tests (matches CI)

```bash
docker compose exec -T web python manage.py test apps        # backend (48 tests)
( cd front  && npm run lint && npm run build )                # dashboard
( cd mobile && flutter analyze && flutter test )              # mobile
```

(Full matrix and per-step expectations in [`TESTING.md`](TESTING.md).)

### Reach the backend from your phone

1. Find your LAN IP: `ip a | grep inet`  (Linux) / `ipconfig` (Windows).
2. Edit `mobile/lib/core/constants/api_constants.dart`:
   `static const String baseUrl = 'http://192.168.x.x:8000/api/';`
3. Edit `.env`: `DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.x.x`
4. `./start.sh --rebuild` (so the new ALLOWED_HOSTS takes effect).
5. Phone on the same Wi-Fi → `flutter run` from `mobile/`.

---

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| `Ports are not available: bind: address already in use` | `./start.sh --stop`, then `lsof -i :8000` (or `:5173`) and kill the holder. |
| Dashboard loads but API calls return CORS errors | You probably opened the **built** `dist/index.html` directly instead of the dev server. Use `npm run dev` so the `/api` proxy works. |
| `npm run dev` says "port 5173 in use" | It'll pick 5174 automatically. Read the printed URL or `tail .dashboard.log`. |
| Login returns 400 `username required` | The form posts `username`, not `phone`. Test accounts are `client1` / `worker1` / `admin1`. |
| `/admin/dashboard` 403 in the browser | You logged in as `client1` / `worker1`. Only `admin1` has `role=admin`. |
| Container stuck `health=starting` | `docker compose logs web --tail=80` — usually a migration error. |
| Migration says "no changes" but you edited a model | You're editing under `core/apps/X/models.py`; `makemigrations` looks at `apps.X` — already correct in this repo, so just re-run `./start.sh --rebuild`. |
| Mobile app says "connection refused" | Wrong `baseUrl` for your device (see §2.3 table). |

---

## 8. What ships in each surface (quick map)

### Backend Django apps (`core/apps/`)

| App | Owns |
|---|---|
| `users` | Auth, roles (client/worker/admin), JWT issue/refresh, profile |
| `workers` | `ServiceCategory`, `WorkerProfile` |
| `orders` | `Order` lifecycle + `OrderAttachment` |
| `payments` | Paymob `CommissionPayment` + webhook |
| `ratings` | Post-job stars |
| `favorites` | Saved workers per client |
| `notifications` | In-app rows + FCM device tokens |
| `admin_api` | REST endpoints under `/api/admin/*` that power the dashboard |

### Dashboard pages (`front/src/pages/`)

| Path | File |
|---|---|
| `/` | `LandingPage.jsx` (uses every component under `components/landing/` and `components/layout/`) |
| `/login` | `Login.jsx` → `components/auth/LoginPage.jsx` (uses `AuthContext.login()`) |
| `/admin/dashboard` | `pages/admin/Dashboard.jsx` (calls `GET /api/admin/dashboard/`) |
| `/admin/users` | `pages/admin/Users.jsx` (`GET /api/admin/users/`) |
| `/admin/workers` | `pages/admin/Workers.jsx` (`GET /api/admin/workers/`) |
| `/admin/categories` | `pages/admin/Categories.jsx` |
| `/admin/orders` | `pages/admin/Orders.jsx` (PATCHes `/api/admin/orders/<id>/status/`) |
| `/admin/payments` | `pages/admin/Payments.jsx` |
| `/admin/ratings` | `pages/admin/Ratings.jsx` |
| anything else | `NotFound.jsx` |

Sidebar links and routes match exactly. Wiring runs through
`routes/AppRoutes.jsx` → `ProtectedRoute` checks `useAuth().user`.

### Mobile features (`mobile/lib/features/`)

`auth · home · workers · details · favorites · orders · checkout · requests · job_history · notifications · profile · account · search · settings · categories · main`.

---

## 9. Related docs

| Need | Read |
|---|---|
| First-time deeper install (Linux primary) | [`INSTALL.md`](INSTALL.md) |
| Run on Windows                            | [`WINDOWS.md`](WINDOWS.md) |
| Whole-system architecture + UML           | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| Test playbook with expected output        | [`TESTING.md`](TESTING.md) |
| End-to-end domain reference               | [`all.md`](all.md) |
