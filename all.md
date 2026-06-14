# Mongez — Complete Project Reference (`all.md`)

> One document that explains the entire system: where data lives, how the
> backend is shaped, how the mobile app talks to it, how Docker glues it all
> together, and what each piece is for. Read top-to-bottom for the full
> picture; jump to a section if you only need one part.

---

## 1. What Mongez actually is

Mongez is a **home-services marketplace** for Egypt. It has two kinds of
end users and one platform operator:

| Role | What they do in the app |
|---|---|
| **Client** | Browses workers by category, places a service order, pays the worker in cash on-site, then rates the worker. |
| **Worker** (technician) | Lists themselves under a profession (Plumbing, Electrical, etc.), receives incoming orders, accepts/rejects them, and marks them complete. |
| **Admin** | Uses the Django admin to manage categories, users, orders, and payments. |

The platform itself earns a **flat commission per accepted order**
(`COMMISSION_AMOUNT`, default 20 EGP). Workers and clients still exchange
the actual job money in cash; **Paymob is only used to collect the
commission** — that's a defining design choice and the entire `payments`
app exists for it.

---

## 2. Top-level layout

```
Mongez/
├── core/                     ← Django project (settings, urls, shared utils)
│   ├── settings.py
│   ├── urls.py
│   ├── permissions.py        ← IsClient / IsWorker / IsAdmin / IsOrderParticipant
│   ├── throttling.py         ← Auth / OrderCreate / Rating scoped throttles
│   ├── wsgi.py · asgi.py
│   └── apps/                 ← Domain apps (each is a Django app)
│       ├── users/            · Auth, profiles, JWT
│       ├── workers/          · Worker profiles + ServiceCategory
│       ├── orders/           · Order lifecycle + attachments
│       ├── notifications/    · In-app rows + FCM device tokens
│       ├── payments/         · Paymob commission + webhook
│       ├── ratings/          · Post-job star ratings
│       └── favorites/        · Saved workers per client
├── mobile/                   ← Flutter app (separate sub-project)
│   └── lib/
│       ├── main.dart                · App entry, MultiBlocProvider, startup auth check
│       ├── core/
│       │   ├── constants/api_constants.dart    · baseUrl
│       │   ├── constants/endpoints.dart        · every path string lives here
│       │   ├── app_themes.dart, app_colors.dart
│       │   └── bloc/                           · global cubits (theme, locale)
│       ├── services/
│       │   ├── api_client.dart                 · Dio + JWT interceptor + refresh
│       │   ├── api_service.dart                · thin GET/POST/PATCH/DELETE wrapper
│       │   ├── helper.dart                     · PrefHelper (SharedPreferences token store)
│       │   ├── services_locator.dart           · GetIt registrations
│       │   └── navigation_service.dart         · post-login routing + cubit resets
│       ├── widgets/                            · reusable UI
│       ├── errors/failure.dart                 · ServerFailure + Dio mapper
│       ├── generated/                          · flutter_intl output
│       └── features/                           · one folder per feature
│           ├── auth/        (models, repos, bloc, screens, onboarding)
│           ├── home/        (categories cubit, sliver app bar, service cards)
│           ├── workers/     (data/domain/presentation — list, detail, create profile)
│           ├── details/     (worker detail view + per-worker ratings)
│           ├── favorites/   (client-only)
│           ├── orders/      (data/domain/presentation — 4 cubits below)
│           ├── checkout/    (place-order flow: address, attachments, payment)
│           ├── requests/    (customer + technician request lists)
│           ├── job_history/ (completed orders for workers)
│           ├── notifications/ (cubit polls every 30 s)
│           ├── profile/     (users/me/ GET/PATCH)
│           ├── account/, search/, settings/, categories/, main/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── requirements.txt
├── .env.example
├── manage.py
├── README.md · INSTALL.md · API_links.md · CONTRIBUTING.md
└── PROJECT_OVERVIEW.md · ENHANCEMENTS.md · DOCKER_VERIFICATION.md · CLOUD_SERVICES.md
```

`lastversion/` is a snapshot of the previous mobile codebase and is **not
used by the running app**. The working app is everything under `mobile/`.

---

## 3. Where the data comes from

**Single source of truth:** the SQLite database file the Django backend
owns.

| Where the file lives | When |
|---|---|
| `db.sqlite3` at the repo root | Local non-Docker `runserver` |
| `/app/data/db.sqlite3` inside the container, persisted to the **`sqlite_data` named volume** | Docker Compose (`SQLITE_PATH` env var, set in `docker-compose.yml`) |

Uploaded files (avatars, order attachments) go to `MEDIA_ROOT` → in
Docker that maps to `/app/media`, persisted to the **`media_data` named
volume**. Both volumes survive `docker compose down` and only get wiped
on `docker compose down -v`.

There is **no external service the mobile app fetches data from
directly** other than this Django API. Paymob and (optionally) FCM are
called server-side. The mobile app only talks to the backend.

Data flow at a glance:

```
                   ┌──────────────────────────────────────────┐
                   │              Flutter mobile              │
                   │  (Dio + JWT interceptor + PrefHelper)    │
                   └──────────────────────────────────────────┘
                              │ HTTPS/HTTP JSON
                              ▼
                   ┌──────────────────────────────────────────┐
                   │  Django REST API   /api/...              │
                   │  Gunicorn (2 workers) inside Docker      │
                   │  apps/users · workers · orders · ...     │
                   └──────────────────────────────────────────┘
                              │            │
                  ┌───────────┘            └──────────────┐
                  ▼                                       ▼
        ┌──────────────────┐                ┌───────────────────────┐
        │   SQLite file    │                │  External services    │
        │  (sqlite_data    │                │  • Paymob (commission)│
        │   named volume)  │                │  • FCM   (push, opt.) │
        └──────────────────┘                └───────────────────────┘
```

---

## 4. Backend — Django REST API

### 4.1 Project shell (`core/`)

`core/settings.py` is the centerpiece. Highlights:

- `AUTH_USER_MODEL = "users.User"` — custom user with phone, governorate,
  role.
- All env reads go through `env_bool` / `env_list` helpers so dev defaults
  stay safe when a variable is missing.
- DRF defaults: JWT auth, `IsAuthenticated`, page size 20, throttles
  configurable via `THROTTLE_*` env vars.
- `SIMPLE_JWT` lifetimes come from `JWT_ACCESS_MINUTES` and
  `JWT_REFRESH_DAYS`; refresh tokens rotate on use.
- `WhiteNoise` serves `/static/` so the Django admin and DRF browsable API
  still look right with `DEBUG=false`.
- Paymob settings (`PAYMOB_API_KEY`, `PAYMOB_INTEGRATION_ID`,
  `PAYMOB_HMAC_SECRET`, `COMMISSION_AMOUNT`) and `FCM_SERVER_KEY` are read
  from env; missing values disable the integration cleanly.

`core/urls.py` mounts every domain app under `/api/`:

```
GET  /api/health/            → {"status":"ok"}     ← used by Docker HEALTHCHECK
     /api/auth/...           → apps.users.urls
     /api/users/me/          → apps.users.urls
     /api/categories/...     → apps.workers.urls
     /api/workers/...        → apps.workers.urls
     /api/orders/...         → apps.orders.urls
     /api/notifications/...  → apps.notifications.urls
     /api/payments/webhook/  → apps.payments.urls
     /api/ratings/...        → apps.ratings.urls
     /api/favorites/...      → apps.favorites.urls
     /admin/                 → Django admin
```

`core/permissions.py` defines `IsClient`, `IsWorker`, `IsAdmin`,
`IsClientOrWorker`, `IsOrderParticipant` — these replace inline `if
request.user.role != X` checks across views.

`core/throttling.py` defines `AuthRateThrottle`, `OrderCreateThrottle`,
`RatingThrottle` — DRF scoped throttles whose rates are read from env.

### 4.2 `apps/users` — accounts and JWT

- **Model `User`** (extends `AbstractUser`): adds `phone` (unique, regex
  validated), `name_ar`, `address`, `governorate` (27 Egyptian
  governorates as TextChoices), `city`, `avatar` ImageField, `role`
  (`client` / `worker` / `admin`).
- **Endpoints**:
  - `POST /api/auth/register/` — anyone. Returns `{user, tokens:{access,refresh}}`.
  - `POST /api/auth/login/` — anyone. Same shape as register.
  - `POST /api/auth/logout/` — blacklists a refresh token (best-effort).
  - `PUT  /api/auth/password/` — change password (returns fresh tokens).
  - `POST /api/auth/token/refresh/` — DRF SimpleJWT default.
  - `GET/PATCH /api/users/me/` — read or update own profile (multipart for
    avatar).
- **Throttling**: register/login/password go through `AuthRateThrottle`
  (default 10/min).
- Cannot register as `admin` (validator in `RegisterSerializer`).

### 4.3 `apps/workers` — worker profiles + categories

Two models:

- **`ServiceCategory`** — name, name_ar, icon, description (en/ar). The
  mobile home screen reads this from `GET /api/categories/`.
- **`WorkerProfile`** — `OneToOne` to a `User` with `role=worker`. Stores
  profession, bio (en/ar), experience, hourly rate, minimum charge,
  specialties (CSV — kept portable for SQLite), languages, response time,
  completion/accept rate, working hours, geo + service radius, verified
  flag, featured flag, computed `average_rating` and `completed_jobs`.
- **Score formula** (used to rank the worker list):
  `(average_rating × 0.6) + (completed_jobs × 0.4)`
  Annotated at the DB level so paginated ordering stays consistent.

Endpoints:

| Method | Path | Who | Behavior |
|---|---|---|---|
| GET | `/api/categories/` | public | List all categories |
| POST | `/api/categories/create/` | admin | Create category |
| GET | `/api/workers/` | public | Paginated list (filters: `category`, `search`, `min_rating`, `available`, `ordering`, `page`, `page_size`) |
| GET | `/api/workers/<id>/` | public | Worker detail |
| GET | `/api/workers/<id>/stats/` | public | Aggregated order + rating analytics for the worker |
| POST | `/api/workers/create/` | worker | Create my worker profile |
| GET/PATCH | `/api/workers/me/` | worker | My own profile |

`WorkerProfileSerializer.service_category` does a case-insensitive lookup
of `ServiceCategory` whose `name` matches the worker's `profession`, with
per-request in-memory caching to avoid N+1 queries.

### 4.4 `apps/orders` — the order lifecycle

This is the heart of the app. State machine:

```
            POST /orders/                 POST /accept/             POST /complete/
client ────────────────► PENDING ──worker────► ACCEPTED ──worker────► COMPLETED
                          │  │                                                 │
                          │  └──worker /reject/──► REJECTED                    ▼
                          └─────client /cancel/──► CANCELLED            client rates
```

`Order` model:

- FK `client` (User), FK `worker` (User, nullable until assigned), FK
  `service_category`.
- `description`, `address_text`, `latitude`/`longitude`, `urgency`
  (LOW/NORMAL/HIGH), `scheduled_for`.
- `commission` (decimal, recorded on accept), `status`, timestamps for
  `created_at`/`accepted_at`/`completed_at`/`cancelled_at`.
- DB indexes on `(status, -created_at)`, `(client, -created_at)`,
  `(worker, -created_at)`.

`OrderAttachment` — image/audio/video uploaded with the order. Max **15
MB per file**, kind inferred from extension, stored under
`media/order_attachments/YYYY/MM/`.

Views (all under `IsAuthenticated`, with role checks inside):

| Path | Action |
|---|---|
| `GET /api/orders/?status=...` | List my orders (client sees own, worker sees assigned) |
| `POST /api/orders/` | **Client only**. Creates the order, attachments, calls Paymob to authorize commission, fans out push notifications to every matching available worker. Throttled by `OrderCreateThrottle` (default 20/hour). |
| `GET /api/orders/<id>/` | Detail, scoped so a client cannot read someone else's order |
| `POST /api/orders/<id>/attachments/` | Add more files after creation |
| `POST /api/orders/<id>/accept/` | Worker accepts → captures commission, sets commission amount, notifies client |
| `POST /api/orders/<id>/reject/` | Worker rejects → voids commission, notifies client |
| `POST /api/orders/<id>/cancel/` | Client cancels (only while PENDING) → voids commission, notifies worker |
| `POST /api/orders/<id>/complete/` | Worker marks done → increments `completed_jobs`, asks client to rate |

Important rules (enforced in views):

- A worker can only complete an order **they were assigned to**.
- A client can only cancel **their own** order and only while `PENDING`.
- Status transitions are guarded — you cannot accept an `ACCEPTED` order,
  cancel a `COMPLETED` one, etc.

### 4.5 `apps/payments` — Paymob commission

This app exists only to charge the platform fee. The flow is **auth →
capture / void**, not a normal charge.

- **`CommissionPayment`** (OneToOne to `Order`): `amount`,
  `paymob_order_id`, `paymob_transaction_id`, `payment_key`,
  `payment_status` ∈ {`AUTHORIZED`, `CAPTURED`, `VOIDED`, `FAILED`}.
- `apps/payments/paymob.py` is the **only file allowed to talk to
  Paymob's REST API**. It exposes:
  - `authorize_commission(order)` → 3-step flow (get auth token → create
    Paymob order → get payment_key). Called from order create.
  - `capture_commission(transaction_id, amount)` → called on worker
    accept.
  - `void_commission(transaction_id)` → called on worker reject or client
    cancel.
- `apps/payments/views.py` has only one view — `PaymobWebhookView`
  (`POST /api/payments/webhook/?hmac=...`). It:
  1. Verifies HMAC-SHA512 against `PAYMOB_HMAC_SECRET`. Rejects on
     mismatch.
  2. Looks up the `CommissionPayment` by `paymob_order_id`.
  3. Saves the `paymob_transaction_id` (needed later for capture/void).
  4. Updates `payment_status` based on `is_voided`/`is_capture`/`success`.
- Mobile **never** calls this endpoint — Paymob calls it from their side.

Failure handling: if Paymob is unavailable, the **order still gets
created** (commission row is marked `FAILED` and logged). Same for
capture/void — payment failures are logged but never block business
logic.

### 4.6 `apps/notifications` — in-app + push

- **`Notification`**: `user`, `title`, `message`, `type`
  (`push`/`in_app`/`email`), `is_read`, `data` (JSON for deep links).
- **`DeviceToken`**: an FCM/APNs token the mobile app registered, scoped
  to a user.
- `services.py` exposes a single `notify(user, title, message,
  notif_type, data)` that always writes the in-app row and, when type is
  `PUSH` and `FCM_SERVER_KEY` is set, fans the payload out to every
  active device token via FCM HTTP. **Push delivery is best-effort and
  never raises.**

Endpoints:

| Method | Path |
|---|---|
| GET | `/api/notifications/` (filter `?unread=1`) |
| GET | `/api/notifications/unread-count/` |
| POST | `/api/notifications/<id>/read/` |
| POST | `/api/notifications/read-all/` |
| POST/DELETE | `/api/notifications/devices/` — register/deregister a device token |

The mobile `NotificationCubit` **polls `GET /notifications/` every 30
seconds** while the main screen is mounted, which is the live-update
mechanism today (no websockets).

### 4.7 `apps/ratings` — post-job stars

- **`Rating`**: OneToOne to `Order`, FK client/worker, `stars` (1–5),
  `review` text. Indexed by `(worker, -created_at)`.
- `POST /api/ratings/` — client only, throttled by `RatingThrottle`
  (default 30/hour). Updates the worker's `average_rating` aggregate.
- `GET /api/ratings/worker/<id>/` — public, last 50 reviews.

### 4.8 `apps/favorites` — saved workers

- **`Favorite`**: FK client + FK worker, `unique_together` on the pair.
- `GET/POST /api/favorites/` (client only).
- `DELETE /api/favorites/<id>/` or `DELETE /api/favorites/worker/<worker_id>/`
  for a toggle-by-worker-id shortcut.

---

## 5. Mobile — Flutter app

### 5.1 Architecture

The app follows **Clean Architecture-ish layering per feature**:

```
features/<name>/
├── domain/        ← repository interface
├── data/
│   ├── models/    ← fromJson/toJson
│   └── repositories/  ← implements domain, calls ApiService
└── presentation/
    ├── cubit/     ← BLoC/Cubit state machine
    └── screens/   ← Material widgets (some features keep screens at feature root)
```

State management is **`flutter_bloc` + cubits**. All cubits are registered
once at app startup in `main.dart` via a `MultiBlocProvider` so any
screen can `context.read<...Cubit>()` without re-instantiation.

Repositories are wired via **`get_it` (`services/services_locator.dart`)**
and use `dartz`'s `Either<Failure, T>` for error handling — every repo
method returns `right(data)` on success or `left(ServerFailure)` on
failure (DioException converted in `errors/failure.dart`).

### 5.2 Networking

`services/api_client.dart` (`DioClient`):

- Base URL: `ApiConstants.baseUrl = 'http://127.0.0.1:8000/api/'` (change
  for emulator/device — see §7).
- Adds `Authorization: Bearer <access>` to every request from
  `PrefHelper.getToken()`.
- **Auto-refresh on 401**: when a request comes back 401, the
  interceptor calls `auth/token/refresh/` with the refresh token, saves
  the new access token, and replays the original request. If refresh
  fails, it clears tokens and invokes the optional `onUnauthorized`
  callback (used to bounce back to the auth flow).

`services/api_service.dart` is a thin wrapper exposing `get / post / put
/ patch / delete / postMultipart / patchMultipart` on top of Dio.

`services/helper.dart` (`PrefHelper`) persists `auth_token` and
`refresh_token` into `SharedPreferences`. There is no encrypted secure
storage today.

`core/constants/endpoints.dart` is the single place every API path is
written. Repositories never hand-type a URL.

### 5.3 App startup (`main.dart`)

1. `setup()` registers GetIt singletons.
2. `AppPrefs.init()` warms up shared prefs.
3. `MultiBlocProvider` builds all cubits (theme, locale, login,
   register, categories, workers, profile, customer/technician orders,
   job history, checkout, favorites, create worker profile,
   notifications).
4. `AppStartupScreen` checks: token in prefs? → call
   `getProfile()` → on success go to `MainScreen`, on failure try
   `/auth/token/refresh/`, on failure again drop to the
   `GetStartedScreen`. This is what makes the app "remember you're
   logged in."

### 5.4 Main navigation (`MainScreen`)

A `BottomNavigationBar` with 4 tabs. The labels differ by role:

| Index | Client | Worker |
|---|---|---|
| 0 | Home (categories + workers) | Home (own profile + orders to action) |
| 1 | Favorites | Job History |
| 2 | Requests (my placed orders) | Requests (incoming orders) |
| 3 | Account | Account |

On entering `MainScreen` the `NotificationCubit.startPolling()` fires
and `_fetch()` runs every 30 s.

### 5.5 How the mobile maps to the API

| Mobile feature | Repository | Endpoints used |
|---|---|---|
| `auth` | `AuthRepoImplementation` | `auth/login/`, `auth/register/`, `auth/token/refresh/` |
| `profile` | `ProfileRepositoryImpl` | `users/me/` (GET + PATCH, multipart for avatar) |
| `home` (categories) | `HomeRepoImplementation` | `categories/` |
| `workers` | `WorkerRepositoryImpl` | `workers/`, `workers/<id>/`, `workers/create/` |
| `details` (worker detail + reviews) | (inline) | `workers/<id>/`, `ratings/worker/<id>/`, `workers/<id>/stats/` |
| `favorites` | `FavoritesRepositoryImpl` | `favorites/`, `favorites/<id>/` |
| `orders` | `OrderRepositoryImpl` | `orders/` (GET + POST multipart with photos/audio), `orders/<id>/`, `accept`, `reject`, `cancel`, `complete` |
| `checkout` | reuses `OrderRepository` | `orders/` POST (with attachments and worker selection) |
| `notifications` | `NotificationRepositoryImpl` | `notifications/`, `notifications/<id>/read/`, `notifications/read-all/` |

### 5.6 Order create — end-to-end

The single most involved flow. Tracing a client tapping **"Book Now"**:

1. **Mobile (`CheckoutCubit`)** collects: category id, optional worker
   id, description, address, urgency, optional GPS lat/lng, optional
   photos[] from `image_picker`, optional audio recorded with `record`.
2. Calls `OrderRepositoryImpl.createOrder(...)`. If files are present it
   builds a `FormData` (`multipart/form-data`) with field names matching
   what the backend expects: `service_category`, `worker_id`,
   `description`, `address_text`, `urgency`, `latitude`, `longitude`,
   `duration_seconds`, files under `photos` and `audio`. Without files it
   sends plain JSON.
3. **Backend (`OrderListCreateView.post`)**:
   - Verifies `request.user.role == CLIENT` (throws 403 otherwise).
   - `OrderCreateSerializer` validates: category exists; if `worker_id`
     given, worker has a profile, is available, and their profession
     matches the category name.
   - Inside one `@transaction.atomic`:
     - Creates the `Order` (status `PENDING`).
     - Walks `request.FILES` and creates `OrderAttachment` rows, skipping
       anything over 15 MB.
     - Calls `paymob.authorize_commission(order)` → 3 API hits to
       Paymob, creates `CommissionPayment` row with status `AUTHORIZED`
       and stores the `payment_key`. On failure a `FAILED` row is logged
       and `payment_key` returned as `None` — the order still exists.
   - Notifies every matching available worker via `notify(...,
     notif_type=PUSH)` so they get a Notification row + (if FCM
     configured) a push.
   - Returns `OrderSerializer(order).data` plus the `payment_key` for
     the mobile to optionally render Paymob's iframe.
4. **Worker side**: their `NotificationCubit` polls every 30 s and shows
   the new entry. They open `TechnicianRequestsScreen`, tap **Accept** →
   `POST /orders/<id>/accept/`. Backend updates status, calls
   `paymob.capture_commission(...)`, sets `commission` on the order, and
   notifies the client.
5. When the job is done in real life, the worker taps **Complete** →
   `POST /orders/<id>/complete/`. Backend bumps the worker's
   `completed_jobs` counter and notifies the client to rate.
6. The client opens the order, taps **Rate** → `POST /ratings/`.

---

## 6. Docker — what the box actually does

### 6.1 `Dockerfile`

- Base: `python:3.12-slim`.
- Installs `libjpeg62-turbo zlib1g` (Pillow), `curl` (for the
  HEALTHCHECK), `gosu` (drop privileges in the entrypoint).
- Creates an unprivileged `app` user (uid 1000).
- `pip install -r requirements.txt` in a separate layer from source
  copy, so editing code doesn't rebuild Python deps.
- Runs `collectstatic` at build time so the admin/DRF browsable API have
  their CSS available without runtime work.
- Sets `chmod +x entrypoint.sh`, creates `/app/data` and `/app/media`,
  chowns to `app`.
- `EXPOSE 8000`.
- `HEALTHCHECK` hits `GET /api/health/` every 30 s, with a 20 s start
  grace.
- `ENTRYPOINT ["/app/entrypoint.sh"]`.

### 6.2 `entrypoint.sh`

Runs briefly as root, then drops to `app` via `gosu`:

1. `mkdir -p /app/data /app/media` and `chown` them so the named volumes
   become writable.
2. `gosu app python manage.py migrate --noinput` — applies any pending
   migrations on every boot.
3. `exec gosu app gunicorn core.wsgi:application --bind 0.0.0.0:8000
   --workers 2 --timeout 120 --access-logfile - --error-logfile -`.

`exec` matters: Gunicorn replaces the shell so it becomes PID 1's
direct child and receives `SIGTERM` cleanly on `docker stop`.

### 6.3 `docker-compose.yml`

```yaml
services:
  web:
    build: .
    image: mongez-backend:latest
    container_name: mongez-backend
    ports: ["8000:8000"]
    env_file: [.env]
    environment:
      SQLITE_PATH: /app/data/db.sqlite3
    volumes:
      - sqlite_data:/app/data         ← database persistence
      - media_data:/app/media         ← uploaded files persistence
    healthcheck: hits /api/health/ every 30 s
    restart: unless-stopped
volumes:
  sqlite_data:
  media_data:
```

Two named volumes intentionally separate from the source tree. `docker
compose down` keeps them. `docker compose down -v` wipes them.

### 6.4 `.dockerignore`

Trims the build context: drops `venv/`, `__pycache__/`, `.git/`,
`.env`, the existing `db.sqlite3`, `media/`, `staticfiles/`, **the
entire `mobile/` directory**, docs, and IDE/OS files. The image only
contains what's needed to serve the API.

### 6.5 `.env`

`.env.example` lists every supported variable. Required for production:
`DJANGO_SECRET_KEY`, `DJANGO_DEBUG=false`, `DJANGO_ALLOWED_HOSTS`.
Paymob and FCM keys can stay blank in dev — both integrations are no-ops
when their secrets are missing.

### 6.6 Operational commands

```bash
docker compose up -d --build        # build + start in background
docker compose ps                   # check status / healthcheck
docker compose logs -f web          # follow logs
docker compose exec web python manage.py createsuperuser
docker compose exec web python manage.py shell
docker compose exec web python manage.py test apps
docker compose down                 # stop, keep volumes
docker compose down -v              # stop, wipe DB + media
```

Health verification:

```bash
curl http://localhost:8000/api/health/        # {"status":"ok"}
curl http://localhost:8000/api/workers/       # paginated empty list
```

---

## 7. Where backend and mobile actually connect

There's no shared code — the contract is the JSON over HTTP:

1. **Mobile sends** `Authorization: Bearer <access>` on every request
   except register/login/refresh.
2. **Mobile knows the base URL** from
   `mobile/lib/core/constants/api_constants.dart` →
   `ApiConstants.baseUrl`. **Change this per target**:

   | Target | Value |
   |---|---|
   | Linux desktop, iOS sim, web | `http://127.0.0.1:8000/api/` |
   | Android emulator | `http://10.0.2.2:8000/api/` |
   | Physical device on Wi-Fi | `http://<your-machine-LAN-IP>:8000/api/` |

3. **For a physical device**: also bind the backend to all interfaces
   (`docker-compose.yml` → `ports: ["0.0.0.0:8000:8000"]`) and add your
   machine's IP (and the emulator host `10.0.2.2`) to
   `DJANGO_ALLOWED_HOSTS`.
4. **Token storage**: mobile keeps access + refresh in
   `SharedPreferences` (plain). On 401 the Dio interceptor swaps to
   refresh, retries, and on failure logs the user out.
5. **Push & live updates**: notifications are **polled** (30 s interval
   while `MainScreen` is mounted). FCM is server-side only and silent
   in dev unless `FCM_SERVER_KEY` is set.
6. **File uploads** use `multipart/form-data`: avatars during register,
   order photos (`photos`) and audio (`audio`).

---

## 8. Branch layout (matters for collaborators)

- `main` — production-ready snapshot of backend + mobile + fixes (current
  branch).
- `backend` — historical: backend-only.
- `mobile` — historical: mobile-only.
- `test` — integration testing branch that merges backend + mobile.

The memory note from previous sessions says **don't push directly to
`main`** — open PRs and merge through `test` first.

---

## 9. Quick reference — every endpoint

```
Auth
  POST  /api/auth/register/                         public
  POST  /api/auth/login/                            public
  POST  /api/auth/logout/                           auth
  PUT   /api/auth/password/                         auth
  POST  /api/auth/token/refresh/                    public

Profile
  GET   /api/users/me/                              auth
  PATCH /api/users/me/                              auth (multipart for avatar)

Categories
  GET   /api/categories/                            public
  POST  /api/categories/create/                     admin

Workers
  GET   /api/workers/                               public  (category, search, min_rating, available, ordering, page, page_size)
  GET   /api/workers/<id>/                          public
  GET   /api/workers/<id>/stats/                    public
  POST  /api/workers/create/                        worker
  GET   /api/workers/me/                            worker
  PATCH /api/workers/me/                            worker

Orders
  GET   /api/orders/                                auth (status filter)
  POST  /api/orders/                                client (multipart with photos/audio)
  GET   /api/orders/<id>/                           auth (scoped)
  POST  /api/orders/<id>/attachments/               client
  POST  /api/orders/<id>/accept/                    worker
  POST  /api/orders/<id>/reject/                    worker
  POST  /api/orders/<id>/cancel/                    client
  POST  /api/orders/<id>/complete/                  worker

Notifications
  GET   /api/notifications/                         auth (?unread=1)
  GET   /api/notifications/unread-count/            auth
  POST  /api/notifications/<id>/read/               auth
  POST  /api/notifications/read-all/                auth
  POST  /api/notifications/devices/                 auth (register FCM token)
  DELETE/api/notifications/devices/                 auth

Payments
  POST  /api/payments/webhook/?hmac=...             Paymob only (HMAC-verified)

Ratings
  POST  /api/ratings/                               client (throttled)
  GET   /api/ratings/worker/<id>/                   public

Favorites
  GET   /api/favorites/                             client
  POST  /api/favorites/                             client
  DELETE/api/favorites/<id>/                        client
  DELETE/api/favorites/worker/<worker_id>/          client

Misc
  GET   /api/health/                                public (used by HEALTHCHECK)
  /admin/                                           Django admin
```

---

## 10. TL;DR

- **Backend** is a Django REST API split into 7 apps under `core/apps/`,
  authenticated with JWT, throttled per-endpoint, served by Gunicorn
  inside a Docker container that auto-applies migrations on boot.
- **Mobile** is a Flutter app under `mobile/` that talks to that API via
  a Dio client with a JWT interceptor; state lives in feature-scoped
  cubits registered globally; repositories return `Either<Failure, T>`.
- **Data** is SQLite plus an uploads directory, both kept on named
  Docker volumes so they survive rebuilds.
- **Paymob** is the only external dependency in the order flow, and only
  for the platform commission. Authorize on create, capture on accept,
  void on reject/cancel. Webhook updates statuses.
- **Push** is via FCM if `FCM_SERVER_KEY` is set; otherwise in-app rows
  only, polled by the mobile every 30 s.
- **Connection point** between mobile and backend is exactly one URL
  (`ApiConstants.baseUrl`) plus the `Authorization: Bearer …` header —
  change the URL per target, keep the contract identical.
