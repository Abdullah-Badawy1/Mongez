# Mongez — Home Services Platform

A full-stack home services app with three components: **Django REST Framework** backend (REST API only — no Django admin), **Flutter** mobile app, and a **React + Vite** web dashboard (public landing page + role-gated admin console). Clients browse workers, place orders, and track them in real time; workers manage incoming requests; admins manage everything from the dashboard.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Django 4.2, Django REST Framework, SimpleJWT |
| Mobile | Flutter 3, Dart, BLoC / Cubit, Dio |
| Dashboard | React 19, Vite 7, React Router 7, react-bootstrap, i18next |
| Auth | JWT (access + refresh tokens with auto-refresh) |
| Database | SQLite (default) |
| Container | Docker + Docker Compose |
| CI | GitHub Actions |

---

## Project Structure

```
Mongez/
├── core/                          # Django project (REST API only)
│   ├── settings.py
│   ├── urls.py
│   └── apps/
│       ├── users/                 # Auth, profiles, roles (CLIENT/WORKER/ADMIN)
│       ├── workers/               # Worker profiles, service categories
│       ├── orders/                # Service order lifecycle + attachments
│       ├── notifications/         # In-app + push notifications
│       ├── payments/              # Paymob commission integration
│       ├── ratings/               # Worker ratings
│       ├── favorites/             # Saved workers
│       └── admin_api/             # REST endpoints for the React dashboard
├── mobile/                        # Flutter app
│   └── lib/
│       ├── core/                  # Theming, localization, helpers
│       ├── services/              # Dio client + service locator
│       ├── errors/                # Failure types
│       └── features/              # Screens by feature (auth, home,
│                                  # workers, orders, favorites, …)
├── front/                         # React + Vite web dashboard
│   ├── src/
│   │   ├── pages/                 # Landing, Login, AdminDashboard, …
│   │   ├── pages/admin/           # Users, Workers, Orders, Categories, …
│   │   ├── components/            # admin/, auth/, common/, landing/, layout/
│   │   ├── services/api.js        # axios client → backend /api/
│   │   ├── context/AuthContext    # JWT session state
│   │   └── locales/{ar,en}/       # i18next translations
│   ├── vite.config.js             # dev proxy: /api → 127.0.0.1:8000
│   └── package.json
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── .env.example
└── requirements.txt
```

---

## Reading order — how to ramp up

The docs are layered so you can stop at any depth. Pick the path that
matches your goal:

| If you want to… | Read in this order |
|---|---|
| **Get it running locally in 30 s** | [`RUNNING.md`](RUNNING.md) (§1) → done. |
| **Understand the whole platform** | this README → [`RUNNING.md`](RUNNING.md) → [`all.md`](all.md) (deep dive, ~900 lines, every app + cubit) → [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) (PlantUML diagrams). |
| **Add a feature** | this README → [`all.md`](all.md) §4 (backend apps) and §5–6 (mobile + dashboard) → [`CONTRIBUTING.md`](CONTRIBUTING.md). |
| **Review a PR** | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the mental model → [`TESTING.md`](TESTING.md) for what to expect when you run the suite → [`PROFESSIONAL.md`](PROFESSIONAL.md) for the engineering bar. |
| **Verify everything works end-to-end** | [`TESTING.md`](TESTING.md) — copy-paste runnable. |
| **Port it to Windows** | [`WINDOWS.md`](WINDOWS.md). |
| **Plan production deployment** | [`PROFESSIONAL.md`](PROFESSIONAL.md) — what's already pro and what to add next, ordered by impact ÷ effort. |
| **Hit a specific endpoint** | [`API_links.md`](API_links.md) — request/response shapes for every URL. |

---

## Quick Start

### Prerequisites

| Tool | Version |
|---|---|
| Docker | 24+ |
| Docker Compose | v2+ |
| Flutter SDK | 3.10+ |
| Git | any |

> No Python installation needed — the backend runs entirely inside Docker.

---

### 1. Clone the repo

```bash
git clone https://github.com/Abdullah-Badawy1/Mongez.git
cd Mongez
```

### 2. Configure environment

```bash
cp .env.example .env
```

Open `.env` and set at minimum:

```env
DJANGO_SECRET_KEY=your-long-random-secret-key
DJANGO_DEBUG=false
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
```

### 3. Start the backend

```bash
docker compose up
```

This will:
- Build the Docker image
- Run all database migrations automatically
- Start the API server on **http://localhost:8000**

Verify it works:

```bash
curl http://localhost:8000/api/workers/
# → {"count":0,"next":null,"previous":null,"results":[]}
```

### 4. Seed initial data

```bash
# Create three test accounts (client1 / worker1 / admin1, all *Pass123):
./start.sh --seed

# Or do it manually from a Django shell:
docker compose exec web python manage.py shell
# → from apps.users.models import User
# → User.objects.create_user(username="admin1", phone="0100…",
#                             password="…", role=User.Role.ADMIN)
```

Manage the data from the React dashboard (admin console) — visit
<http://localhost:5173/admin> after logging in as an admin.

### 5. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run
```

Choose your target device:

```bash
flutter run -d linux    # Linux desktop
flutter run -d chrome   # Web browser
flutter run             # Android / iOS device
```

### 6. Run the web dashboard

```bash
cd front
cp .env.example .env       # set VITE_ADMIN_URL and optional VITE_OPENROUTER_KEY
npm install
npm run dev                # → http://localhost:5173
```

The dev server proxies `/api` and `/media` to the Django backend on `127.0.0.1:8000`. Sign in with any user marked `role=admin` to reach `/admin` routes.

**Live data sync.** Every admin screen polls the backend on a per-page
interval and shows an "Updated Xs ago" badge. A mobile action (e.g. a
client placing an order) lands in the dashboard within ~10 s; an admin
action (e.g. flipping an order status) lands in the mobile app within
~30 s via the order-list cubit poll and lights up the notification bell
via the notification cubit poll. Status-change PATCHes also use
optimistic updates so the admin doesn't wait a tick to see their click
land. See [§ Live data sync in RUNNING.md](RUNNING.md) for the full
matrix and the cache TTL.

Production build:

```bash
npm run build              # static bundle in front/dist/
# Deploy via Firebase Hosting (firebase.json is already configured):
# firebase deploy --only hosting
```

---

## API Overview

Base URL: `http://localhost:8000/api/`

All protected endpoints require:
```
Authorization: Bearer <access_token>
```

| Area | Endpoints |
|---|---|
| Auth | `POST auth/register/` `POST auth/login/` `POST auth/token/refresh/` |
| Profile | `GET/PATCH users/me/` |
| Reference data | `GET governorates/` (public — 27 Egyptian governorates with code, name_en, name_ar) |
| Categories | `GET categories/` |
| Workers | `GET workers/` `GET workers/<id>/` `POST workers/create/` `GET/PATCH workers/me/` `GET workers/me/stats/` |
| Orders | `GET/POST orders/` `POST orders/<id>/accept\|reject\|cancel\|complete\|confirm-completion/` (two-step handshake: worker `complete` → `WAITING_CONFIRMATION` → client `confirm-completion` → `COMPLETED`) |
| Notifications | `GET notifications/` `POST notifications/read-all/` |
| Ratings | `POST ratings/` |
| Favorites | `GET/POST favorites/` `DELETE favorites/<id>/` |
| Admin (dashboard) | `GET admin/dashboard/` (5 s cache) · `GET/POST admin/users/` `GET/PATCH/DELETE admin/users/<id>/` · `GET admin/workers/?status=complete\|incomplete` (returns `complete_count` + `incomplete_count`) `GET admin/workers/<id>/` · `PATCH/DELETE admin/categories/<id>/` · `PATCH admin/orders/<id>/status/` (fans out to client + worker notifications) · `GET admin/payments/` · `GET admin/ratings/` (enriched with client / worker / profession) |

Full request/response details: see [`API_links.md`](API_links.md).

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DJANGO_SECRET_KEY` | — | **Required.** Django secret key |
| `DJANGO_DEBUG` | `false` | Enable debug mode |
| `DJANGO_ALLOWED_HOSTS` | `localhost,127.0.0.1` | Comma-separated allowed hosts |
| `CORS_ALLOW_ALL_ORIGINS` | `false` | Allow all CORS origins |
| `CORS_ALLOWED_ORIGINS` | — | Explicit allowed origins |
| `JWT_ACCESS_MINUTES` | `60` | Access token lifetime (minutes) |
| `JWT_REFRESH_DAYS` | `7` | Refresh token lifetime (days) |
| `PAYMOB_API_KEY` | — | Paymob API key (optional) |
| `PAYMOB_INTEGRATION_ID` | `0` | Paymob integration ID |
| `PAYMOB_HMAC_SECRET` | — | Paymob HMAC secret |
| `COMMISSION_AMOUNT` | `20` | Flat commission per order (EGP) |

---

## Mobile — Device Configuration

**Android emulator** — the emulator cannot reach `localhost`. Update `mobile/lib/core/api/api_constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/';
```

**Physical device on Wi-Fi** — use your machine's LAN IP:

```dart
static const String baseUrl = 'http://192.168.1.X:8000/api/';
```

Also start the backend bound to all interfaces:

```yaml
# docker-compose.yml
ports:
  - "0.0.0.0:8000:8000"
```

---

## One-shot launchers

The repo ships two launchers that wrap the whole platform — backend
container, React dashboard (Vite dev server), and the Flutter mobile
app — behind a single command.

### Linux / macOS (`start.sh`)

```bash
./start.sh                       # backend only
./start.sh --all                 # backend + dashboard + mobile + seed accounts
./start.sh --seed --dashboard    # backend + dashboard, seeded
./start.sh --rebuild             # force a clean image rebuild
./start.sh --stop                # stop backend + dashboard (volumes preserved)
./start.sh --down                # stop + WIPE database/uploads
./start.sh --status              # docker compose ps
./start.sh --logs                # follow backend logs
./start.sh --help                # print all flags
```

### Windows (`start.ps1`)

```powershell
./start.ps1                      # backend only
./start.ps1 -All                 # backend + dashboard + mobile + seed accounts
./start.ps1 -Seed -Dashboard     # backend + dashboard, seeded
./start.ps1 -Rebuild             # force a clean image rebuild
./start.ps1 -Stop                # stop backend + dashboard
./start.ps1 -Down                # stop + WIPE database/uploads
./start.ps1 -Status              # docker compose ps
./start.ps1 -FollowLogs          # follow backend logs
Get-Help ./start.ps1 -Detailed   # full parameter help
```

For a complete Windows porting walkthrough (WSL2, Docker Desktop,
Node, Flutter, line-ending hygiene, troubleshooting) see
[**WINDOWS.md**](WINDOWS.md).

---

## Useful manual commands (no launcher)

```bash
# Backend
docker compose up -d                         # start in background
docker compose down                          # stop
docker compose logs -f web                   # stream logs
docker compose exec web python manage.py shell

# Dashboard
cd front && npm install && npm run dev       # dev server on :5173
cd front && npm run build                    # production bundle in front/dist

# Mobile
flutter pub get                              # install packages
flutter analyze                              # static analysis
flutter test                                 # run unit tests
flutter build apk --release                  # build Android APK
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Installation

* **Step-by-step run guide:**    [RUNNING.md](RUNNING.md)  ← start here
* Generic step-by-step install:  [INSTALL.md](INSTALL.md)
* Windows-specific guide:        [WINDOWS.md](WINDOWS.md)
* Architecture & UML diagrams:   [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
* Step-by-step testing playbook: [TESTING.md](TESTING.md)
* **Production-grade guide & checklist:** [PROFESSIONAL.md](PROFESSIONAL.md)

---

## License

MIT
