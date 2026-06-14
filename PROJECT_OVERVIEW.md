# Mongez — Complete Project Guide

A single document that explains **everything** about this project: what each piece
of the backend and mobile app does, every technology used (with honest pros and
cons), what should be improved next, and a step-by-step plan if you ever need to
build this from zero.

> Companion documents:
> - [`README.md`](README.md) — quick orientation
> - [`INSTALL.md`](INSTALL.md) — how to run it
> - [`API_links.md`](API_links.md) — REST endpoint reference
> - [`ENHANCEMENTS.md`](ENHANCEMENTS.md) — recent enhancement pass changelog
> - [`DOCKER_VERIFICATION.md`](DOCKER_VERIFICATION.md) — Docker smoke-test results
> - [`CONTRIBUTING.md`](CONTRIBUTING.md) — coding conventions

---

## 1. What is Mongez?

A two-sided marketplace for home services in Egypt:

- **Clients** browse workers by category (plumbing, electrical, …), book a job,
  pay a small platform commission via Paymob, then settle the rest of the price
  with the worker in cash.
- **Workers** see incoming orders, accept or reject them, mark jobs as complete,
  and accumulate ratings + completed-jobs metrics that drive their visibility
  in search.

Two deployable artifacts:

| Component | Stack | Where it runs |
|---|---|---|
| Backend REST API | Django 4.2 + DRF + SimpleJWT, SQLite (default) or PostgreSQL | Docker container, port `8000` |
| Mobile app | Flutter 3.10 + BLoC + Dio | Linux desktop, Android, iOS, Web |

---

## 2. Backend (Django REST API)

### 2.1 Project layout

```
core/
├── settings.py        # All Django settings (env-driven via os.getenv)
├── urls.py            # /api/ root + admin + media in DEBUG
├── permissions.py     # IsClient / IsWorker / IsAdmin / IsOrderParticipant
├── throttling.py      # Auth, OrderCreate, Rating throttle classes
├── wsgi.py / asgi.py
└── apps/
    ├── users/         # AUTH_USER_MODEL = users.User
    ├── workers/       # ServiceCategory + WorkerProfile
    ├── orders/        # Order state machine
    ├── payments/      # CommissionPayment + Paymob client + webhook
    ├── ratings/       # Rating (1-5 stars per completed order)
    ├── favorites/     # Client → Worker many-to-many
    └── notifications/ # Notification + DeviceToken (FCM)

manage.py              # Adds core/ to sys.path so apps.* resolves
requirements.txt       # 9 packages; see §4
Dockerfile             # Slim Python 3.12 image, non-root, healthcheck
docker-compose.yml     # web service + sqlite_data + media_data volumes
entrypoint.sh          # chown volumes → migrate → exec gunicorn (gosu)
.env.example           # Every env var documented
```

### 2.2 Each app in one paragraph

**`users`** — Custom `User` extends `AbstractUser` with `phone` (unique,
regex-validated), `address`, `avatar` (ImageField), and a `role` text field
(`client` / `worker` / `admin`). `RegisterView` creates accounts (admins blocked
from self-registration), `LoginView` issues SimpleJWT tokens, `MyProfileView`
gets/patches `users/me/`, `PasswordChangeView` rotates tokens, `LogoutView`
blacklists the refresh token if blacklist is installed. Both auth views are
throttled at `10/min`.

**`workers`** — `ServiceCategory` (name + icon + description) and
`WorkerProfile` (one-to-one with `User` of role=worker; profession, bio,
hourly_rate, experience_years, is_available, denormalized `average_rating` and
`completed_jobs`). `WorkerListView` returns paginated workers, with DB-level
score sorting (`avg_rating × 0.6 + completed_jobs × 0.4`), filters by
`category`, `search`, `min_rating`, `available`, and `ordering`.
`WorkerStatsView` returns acceptance rate + rating distribution for one worker.
`MyWorkerProfileView` is the worker's self-management endpoint.

**`orders`** — Single `Order` model with five states: `PENDING → ACCEPTED →
COMPLETED`, plus `REJECTED` and `CANCELLED` terminal states. `OrderListCreateView`
posts a new order (client only), authorizes a Paymob commission hold, and
notifies eligible workers. State-transition views (`accept`, `reject`,
`cancel`, `complete`) are role-gated. On accept, the Paymob hold is captured;
on reject/cancel it's voided. On complete, the worker's `completed_jobs`
counter increments. Order creation is throttled at `20/hour`.

**`payments`** — `CommissionPayment` is one-to-one with `Order` and tracks the
flat commission (default 20 EGP). The `paymob.py` module is the **only** place
that talks to Paymob's REST API: `authorize_commission` (3-step auth → order →
payment_key), `capture_commission`, `void_commission`. `PaymobWebhookView`
receives Paymob's callback, verifies the HMAC-SHA512 signature using the
documented field order, and updates the payment status. Client and worker
settle the rest of the price in **cash** — Paymob is only used for the platform
cut.

**`ratings`** — A `Rating` row exists at most once per `Order` (one-to-one).
Validators ensure: only the order's client can rate, only after the order is
completed, only once. Saving a rating recomputes the worker's average rating
on the fly. `WorkerRatingsListView` is a public read-only endpoint that
exposes the latest 50 reviews with the rater's display name (no PII).

**`favorites`** — `Favorite` is a unique `(client, worker)` pair.
`FavoriteListCreateView` lets clients heart a worker; `FavoriteDeleteView`
removes by row id; `FavoriteByWorkerDeleteView` is the convenient
"un-heart this worker" toggle that doesn't require knowing the row id.

**`notifications`** — Two models: `Notification` (per-user inbox row with
`title`, `message`, `type`, `is_read`, `data` JSON for deep-link payloads) and
`DeviceToken` (FCM tokens, idempotent registration). The `services.notify(...)`
function is the **single entry point** used everywhere — it always writes the
in-app row and, when the type is `push` and `FCM_SERVER_KEY` is set, fans out
to every active device token. Failures are swallowed because push delivery
must never block business logic.

### 2.3 The order state machine

```
       create order (client)
              │
              ▼
          ┌────────┐
          │ PENDING│──cancel (client)──▶ CANCELLED  (Paymob void)
          └────────┘                     ▲
              │                          │
       accept │                  reject (worker) ──▶ REJECTED  (Paymob void)
       (worker│ → Paymob capture)
              ▼
          ┌────────┐
          │ACCEPTED│
          └────────┘
              │
       complete (worker) → ratings unlocked, completed_jobs++
              ▼
          ┌────────┐
          │COMPLETED│
          └────────┘
```

### 2.4 URL map (all endpoints)

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/api/health/` | none | Liveness probe |
| POST | `/api/auth/register/` | none | Create account |
| POST | `/api/auth/login/` | none | Get tokens |
| POST | `/api/auth/logout/` | bearer | Blacklist refresh |
| PUT | `/api/auth/password/` | bearer | Change password |
| POST | `/api/auth/token/refresh/` | none | Rotate access |
| GET/PATCH | `/api/users/me/` | bearer | Self profile |
| GET | `/api/categories/` | none | List categories |
| POST | `/api/categories/create/` | admin | Create category |
| GET | `/api/workers/` | none | Search/list workers |
| POST | `/api/workers/create/` | worker | Create profile |
| GET/PATCH | `/api/workers/me/` | worker | Self profile |
| GET | `/api/workers/<id>/` | none | Detail |
| GET | `/api/workers/<id>/stats/` | none | Analytics |
| GET/POST | `/api/orders/` | bearer | List/create |
| GET | `/api/orders/<id>/` | participant | Detail |
| POST | `/api/orders/<id>/{accept,reject,cancel,complete}/` | role-gated | Transition |
| POST | `/api/ratings/` | client | Rate completed order |
| GET | `/api/ratings/worker/<user_id>/` | none | Public reviews |
| GET/POST | `/api/favorites/` | client | List/add |
| DELETE | `/api/favorites/<id>/` | client | Remove by row id |
| DELETE | `/api/favorites/worker/<id>/` | client | Remove by worker id |
| GET | `/api/notifications/` | bearer | Inbox |
| GET | `/api/notifications/unread-count/` | bearer | Badge counter |
| POST | `/api/notifications/read-all/` | bearer | Mark all read |
| POST | `/api/notifications/<id>/read/` | bearer | Mark one |
| POST/DELETE | `/api/notifications/devices/` | bearer | FCM token |
| POST | `/api/payments/webhook/` | HMAC | Paymob callback |

### 2.5 Database

SQLite by default (single file in `/app/data/db.sqlite3` inside the container,
backed by a named volume so it survives rebuilds). PostgreSQL is one config
change away — `psycopg2-binary` is already in `requirements.txt`.

Indexes (all added during the enhancement pass):
- `User`: `(role)`, `(phone)`
- `WorkerProfile`: `(is_available, -average_rating)`, `(profession)`
- `Order`: `(status, -created_at)`, `(client, -created_at)`, `(worker, -created_at)`
- `Favorite`: `(client, -created_at)`
- `Rating`: `(worker, -created_at)`
- `Notification`: `(user, is_read)`, `(-created_at)`
- `DeviceToken`: `(user, is_active)`

### 2.6 Auth flow

```
1. POST /api/auth/register/ or /login/  → { access, refresh } tokens
2. App stores them in SharedPreferences
3. Every API call:  Authorization: Bearer <access>
4. On 401, Dio interceptor calls /api/auth/token/refresh/ with the refresh
5. Refresh succeeds → retry original request
6. Refresh fails  → wipe tokens + cache, route to login
```

JWT settings (env-tunable): `JWT_ACCESS_MINUTES=60`, `JWT_REFRESH_DAYS=7`,
`ROTATE_REFRESH_TOKENS=true` (each refresh issues a new refresh token).

### 2.7 Throttling

| Scope | Default | Where it applies |
|---|---|---|
| `anon` | `30/min` | All anonymous endpoints |
| `user` | `120/min` | All authenticated endpoints |
| `auth` | `10/min` | Login / register / password change |
| `order_create` | `20/hour` | `POST /api/orders/` |
| `rating` | `30/hour` | `POST /api/ratings/` |

Rates are env-tunable via `THROTTLE_*`. **Caveat:** DRF's default rate-limit
cache is per-process (`LocMemCache`); with Gunicorn 2 workers this means the
counters are inconsistent across workers. For production, swap in a Redis
cache (see §6 Improvements).

### 2.8 Tests

32 backend tests split across all 7 apps; covered:
- Auth: register, admin-block, duplicate phone, login, bad password, password change
- Workers: list ordering, category filter, min_rating, search, stats endpoint, profile create idempotency, profile patch
- Orders: client creates pending, worker accepts, complete increments jobs, role guards, double-accept blocked, cancel pending
- Ratings: rate completed, block others' orders, block pending, public reviews
- Favorites: add, dedup, remove by worker id, role guard
- Notifications: persist row, unread count, mark all read, device token idempotency

Run: `docker compose exec web python manage.py test apps` → `Ran 32 tests in 2.5s — OK`

---

## 3. Mobile app (Flutter)

### 3.1 Folder structure

```
mobile/lib/
├── main.dart                 # Boot: AppPrefs → BLoC providers → MaterialApp
│
├── core/
│   ├── api/
│   │   ├── api_client.dart   # Singleton Dio + JWT interceptor + refresh
│   │   ├── api_constants.dart # Every endpoint as a constant
│   │   └── api_error.dart     # Normalize Dio errors → 1 user message
│   ├── cache/
│   │   └── json_cache.dart    # TTL SharedPreferences wrapper
│   ├── ui/
│   │   └── snack.dart         # Snack.error / .success / .info
│   ├── validators.dart        # Reusable form validators
│   ├── helpers.dart           # AppPrefs (SharedPreferences wrapper)
│   ├── app_themes/            # Light + dark Material themes
│   ├── app_colors.dart, app_text_styles.dart
│   ├── models/                # User, Worker, Order, Notification, Favorite
│   ├── services/              # Auth, Worker, Order, Notification, Favorite
│   └── bloc/                  # Cubits + states for each feature
│
├── features/                  # Screens organised by domain
│   ├── login_feature/         # Onboarding, register, login, choose role
│   ├── home_feature/          # Worker list + categories
│   ├── details/               # Worker detail
│   ├── checkout_feature/      # Address, cards, payment iframe stub
│   ├── orders/                # (and t_jop_history, t_requestes, requistes)
│   ├── favoirite/             # Favorites screen (typo'd folder)
│   ├── account/               # User profile + add service
│   ├── settings_feature/      # Theme + language toggle
│   └── main_screen/           # Bottom nav shell
│
├── widgets/                   # Reusable UI: button, text field, app bar, …
├── generated/intl/            # ARB → Dart i18n
└── l10n/                      # Arabic + English strings
```

### 3.2 State management — BLoC (Cubit pattern)

Every feature has a Cubit class and a State class. Pattern:

```dart
class WorkersCubit extends Cubit<WorkersState> {
  Future<void> load(...) async {
    emit(WorkersLoading());
    try {
      final workers = await _service.getWorkers(...);
      emit(WorkersLoaded(workers));
    } catch (e) {
      emit(WorkersError(_msg(e)));     // ApiError.message, never raw e.toString()
    }
  }
}
```

Cubits are wired via `BlocProvider` near the screens that use them.

### 3.3 Service layer

Each service wraps Dio and **always throws `ApiError`** (never raw
`DioException`). Call sites get a single normalized error type with
`message`, `statusCode`, and helpers `isUnauthorized`/`isForbidden`/
`isThrottled`/`isNotFound`.

### 3.4 Caching

`JsonCache` (in `core/cache/json_cache.dart`) is a TTL-aware wrapper around
SharedPreferences:

| Data | TTL | Stale fallback |
|---|---|---|
| Categories | 6 hours | Yes (offline-first) |
| Workers default page | none | Yes (used when network fails) |
| My orders | invalidated on every transition | Yes |

Logout calls `JsonCache.clearAll()` so a different account on the same device
starts clean.

### 3.5 Localization

Arabic + English ARB files at `lib/l10n/intl_*.arb`, generated to
`lib/generated/l10n.dart` via `flutter_intl`. The app reads system locale on
first run and persists user override in `SharedPreferences`.

### 3.6 Key screens

| Screen | Calls |
|---|---|
| `GetStartedScreen` → `ChooseAccount` | none |
| `RegisterScreen` | `POST /auth/register/` |
| `LoginScreen` | `POST /auth/login/` |
| `HomeScreen` | `GET /categories/` + `GET /workers/` |
| `DetailsView` | `GET /workers/<id>/` (+ optional `/stats/`) |
| `CheckoutScreen` | `POST /orders/` (Paymob iframe is a stub today) |
| `RequistesScreen` (worker) | `GET /orders/?status=PENDING` |
| `JobHistory` | `GET /orders/?status=COMPLETED` |
| `FavoritesScreen` | `GET/POST/DELETE /favorites/` |
| `AccountScreen` | `GET/PATCH /users/me/` |
| `SettingsPage` | toggles theme + locale only |

---

## 4. Technologies — what, pros, cons

### 4.1 Backend

| Tech | Role | Pros | Cons |
|---|---|---|---|
| **Python 3.12** | Runtime | Fast iteration, huge ecosystem, ML-friendly | GIL limits CPU-bound throughput; runtime errors a typed lang would catch |
| **Django 4.2 LTS** | Web framework | Batteries included (admin, ORM, auth, migrations); LTS until April 2026 | Heavy for microservices; ORM hides query cost; sync request model |
| **DRF 3.15** | REST layer | Browsable API, serializer validation, throttling, pagination — all out of the box | Class-based views verbose; nested serializers can be hard to reason about; not async-native |
| **SimpleJWT 5.3** | Token auth | Stateless tokens, refresh flow, blacklist support, well-documented | No revoke without DB blacklist; refresh token in client storage is a footgun on mobile |
| **SQLite** (default) | DB | Zero ops, file-based, fast for small apps | Single writer, weak `ALTER TABLE`, not multi-host; no concurrent migrations |
| **PostgreSQL** (optional) | DB | Real concurrency, JSONB, full-text search, partial indexes, mature tooling | Needs ops; more memory; connection pooling story (pgBouncer) extra |
| **psycopg2-binary** | PG driver | Stable, widely deployed | Synchronous; switch to `psycopg[binary]` v3 for async; binary wheels not for prod per upstream advice |
| **Pillow 12** | Image handling | Industry standard for Python image I/O | Native deps; CVE history; large memory footprint on big images |
| **gunicorn 26** | WSGI server | Battle-tested, simple workers, easy to operate | Sync model; one slow request blocks a worker; no WebSockets without ASGI |
| **WhiteNoise 6.6** | Static files | Serves /static/ from the app — no Nginx required for small deploys | CPU cost vs. CDN; no media file serving; cache headers tunable but not optimal |
| **django-cors-headers 4.9** | CORS | Trivial to configure | Misconfiguration commonly leaks credentials cross-origin |
| **requests 2.33** | HTTP client | Universal, mature | Sync only; in production use connection pooling / `httpx` with retries |
| **Paymob (REST)** | Payments | Local provider for Egypt; supports auth/capture/void; iframe + cards | Egyptian-only; HMAC field order rigid; sandbox vs prod parity gaps |

### 4.2 Mobile

| Tech | Role | Pros | Cons |
|---|---|---|---|
| **Flutter 3.10** | UI framework | Single codebase → Android, iOS, Linux, macOS, Windows, Web; Skia-rendered consistent UI | Larger app size than native; weak platform-channels DX; Wayland still rough |
| **Dart 3.10** | Language | Sound null safety, modern syntax, hot reload, isolates | Smaller community vs JS/TS; limited server-side adoption |
| **flutter_bloc 9.1** | State mgmt | Predictable, testable, great devtools | Boilerplate-heavy compared to Riverpod; learning curve for newcomers |
| **Dio 5.9** | HTTP client | Interceptors, request cancellation, FormData, multipart upload | Heavier than `package:http`; some breaking changes between majors |
| **shared_preferences 2.5** | Key-value store | Tiny, no async setup | Not encrypted; small payloads only; not for sensitive secrets long-term |
| **intl 0.20 + flutter_intl** | i18n | Standard Flutter approach; ARB editor support | ARB workflow noisy; codegen step needed |
| **flutter_svg 2.2** | SVG rendering | Crisp at any DPI; supports most SVG features | CPU-heavy on complex SVGs; no full SVG2 support |
| **GTK3 (Linux desktop)** | Native shell | Real native window for QA | Wayland cursor warnings (cosmetic); needs CMake/Ninja/libblkid at build time |

### 4.3 Infrastructure

| Tech | Role | Pros | Cons |
|---|---|---|---|
| **Docker 29 + Compose v2** | Packaging + orchestration | Reproducible builds, named volumes, healthchecks, easy local dev | Image bloat; multi-arch builds need buildx; cgroup quirks on some kernels |
| **gosu** | Privilege drop | Cleanest way to run entrypoint as root then drop to a user | Adds an external dep; not in busybox |
| **bash/sh entrypoint** | Boot script | Trivial to read, debug, edit | No structured error handling vs. a Python entrypoint |

---

## 5. Security & operational notes

- **JWT in SharedPreferences (mobile)** — fine for typical apps, but for a real
  bank-grade product use `flutter_secure_storage` (Keychain / KeyStore).
- **Paymob HMAC verification** — already implemented correctly with the documented
  field concatenation order, but rotate the HMAC secret after any leak.
- **CORS** — `CORS_ALLOW_ALL_ORIGINS=true` is OK in dev; flip to false + explicit
  origins in production.
- **DEBUG=False in prod** — already the default in `.env.example`.
- **Static files via WhiteNoise** — fine up to ~1 RPS of static; use a CDN above that.
- **DB on a single SQLite file** — survives container rebuild via volume, but a
  full restore plan is **your job** (cron `pg_dump` once on PostgreSQL).
- **Rate limiting cache** — per-process today; needs Redis for shared throttling.
- **Paymob credentials in `.env`** — never commit the file (already in `.gitignore`).
- **Container runs as uid 1000** — verified via `/proc/1/status`.
- **HEALTHCHECK** — Docker reports `(healthy)` once `/api/health/` returns 200.

---

## 6. What to improve next, and how

Concrete and ordered by impact-to-effort.

### 6.1 Wire the unauthorized-callback to the navigator (low effort, high UX win)
The new `ApiClient.onUnauthorized(...)` hook is in place but no one calls it
yet. In `main.dart`, after constructing the singleton client, call
`ApiClient().onUnauthorized(() { navigatorKey.currentState?.pushAndRemoveUntil(login) })`
so a 401 anywhere in the app routes back to login automatically.

### 6.2 Wire FCM into the mobile app
- Add `firebase_messaging` and `firebase_core` to `pubspec.yaml`.
- Boot Firebase in `main.dart` (`Firebase.initializeApp(...)`).
- After login, call `FirebaseMessaging.instance.getToken()` and POST it to
  `/api/notifications/devices/`.
- Backend already supports it — just set `FCM_SERVER_KEY` in `.env`.

### 6.3 Move the throttle cache to Redis
- Add `redis:` service to `docker-compose.yml`.
- Add `django-redis` to `requirements.txt`.
- In `settings.py`:
  ```python
  CACHES = {"default": {
      "BACKEND": "django_redis.cache.RedisCache",
      "LOCATION": os.getenv("REDIS_URL", "redis://redis:6379/1"),
  }}
  ```
- Throttle counters become coherent across all gunicorn workers.

### 6.4 Switch SQLite → PostgreSQL
- `docker-compose.yml` adds a `db:` service running `postgres:16-alpine`.
- `settings.py` uses `dj-database-url` to read `DATABASE_URL`.
- Run migrations once, reseed via fixtures or admin.

### 6.5 Real Paymob iframe in Flutter
- Today: `OrderCreateView` returns a `payment_key` but the mobile checkout
  screen is a stub.
- Use a Flutter `WebView` widget pointed at
  `https://accept.paymob.com/api/acceptance/iframes/<INTEGRATION_ID>?payment_token=<key>`.
- Listen for the success/fail postMessage and call your backend to refresh the
  order's status.

### 6.6 Folder rename clean-up
`mobile/lib/features/{favoirite, t_jop_history, t_requestes, requistes}` are
typo'd — pure cosmetic but blocks newcomers. Renames touch many imports; one
focused PR with `rg`-driven edits.

### 6.7 Type safety / freezed models
Manual `fromJson` constructors are correct but verbose and easy to drift.
Adopt `freezed` + `json_serializable` so models are immutable, copy-with'd, and
JSON-parsed via codegen.

### 6.8 Hide cleartext-traffic on Android / iOS for prod
The mobile app uses `http://` in dev (Docker on localhost). Production must
use `https://` with a real cert, and Android should drop the
`usesCleartextTraffic="true"` flag from the manifest.

### 6.9 Real WebSocket order updates
Polling + push are fine for now. For "live order tracking" UX, add Django
Channels + `channels_redis` and emit `order.updated` events from each state
transition. Mobile subscribes via `web_socket_channel`.

### 6.10 CI gate
GitHub Actions exists (per recent commits). Tighten it to:
- Run `python manage.py test apps`
- Run `flutter analyze` and `flutter test`
- Build the Docker image and run the smoke-test script on every PR.

### 6.11 Observability
- Drop in `django-prometheus` for backend metrics.
- Use `logging.config.dictConfig` to ship structured JSON to stdout.
- Wire the mobile app to Firebase Crashlytics or Sentry for client errors.

### 6.12 Test the Paymob webhook
The only un-tested code path. Mock the Paymob HTTP client + a fixture HMAC and
assert the four state transitions. ~50 lines.

### 6.13 Object storage for media
`media_data` is a local Docker volume. Add `django-storages[s3]` and point
`DEFAULT_FILE_STORAGE` at S3/R2 so avatars survive multi-host deploys.

---

## 7. Building this app from zero — step-by-step

If you had to recreate Mongez from a blank repo, here is the order I'd do it
in. Each step yields a *runnable* artifact so you never have a half-built
system.

### Step 0 — Tooling
1. Install Docker 24+, Git, Python 3.12, Flutter 3.10+.
2. `git init && git remote add origin git@github.com:you/mongez.git`.
3. Pick license + add `.gitignore` (Python + Flutter sections).

### Step 1 — Backend skeleton (1 hour)
1. `python -m venv venv && source venv/bin/activate`.
2. `pip install Django djangorestframework djangorestframework-simplejwt
   django-cors-headers psycopg2-binary requests gunicorn Pillow whitenoise`.
3. `django-admin startproject core .`
4. Create `core/apps/` directory and 7 app folders:
   `users workers orders payments ratings favorites notifications`.
5. Wire `manage.py` to add `core/` to `sys.path`:
   ```python
   sys.path.append(os.path.join(os.path.dirname(__file__), 'core'))
   ```
6. In each app, run `python manage.py startapp <name> core/apps/<name>`.

### Step 2 — Custom user (15 min)
Define `users.User(AbstractUser)` with `phone`, `address`, `role`, `avatar`
**before** you run any migration. Set `AUTH_USER_MODEL = "users.User"` in
`settings.py`. Migrate.

### Step 3 — Auth + JWT (30 min)
1. Add `users` to `INSTALLED_APPS`.
2. `RegisterSerializer` validates phone uniqueness, password strength,
   blocks self-registration as admin.
3. `RegisterView`, `LoginView`, `MyProfileView`, `PasswordChangeView`.
4. Wire `simplejwt` settings (`ACCESS_TOKEN_LIFETIME`,
   `ROTATE_REFRESH_TOKENS=True`).
5. URL config under `/api/auth/`.
6. Smoke-test: register → login → curl `/users/me/` with bearer.

### Step 4 — Workers + categories (45 min)
1. `ServiceCategory(name, icon, description)`.
2. `WorkerProfile(user OneToOne, profession, bio, hourly_rate,
   experience_years, average_rating, completed_jobs, is_available)`.
3. `WorkerListView` with `select_related("user")`, DB-level score annotation
   via `F() expressions`, and query params for `category`, `search`,
   `min_rating`, `available`, `ordering`.
4. `WorkerStatsView` aggregates from `Order` + `Rating`.
5. `MyWorkerProfileView` for self-management.
6. Indexes: `(is_available, -average_rating)`, `(profession)`.

### Step 5 — Orders + state machine (1 hour)
1. `Order(client, worker, service_category, status, commission, created_at,
   accepted_at, completed_at, cancelled_at)`.
2. Status constants + a serializer that exposes them.
3. Five views, each `@transaction.atomic`: `OrderListCreateView`,
   `OrderDetailView`, `OrderAccept/Reject/Cancel/CompleteView`.
4. On `accept`, capture Paymob commission. On `reject`/`cancel`, void it. On
   `complete`, increment `worker_profile.completed_jobs`.
5. Indexes: `(status, -created_at)`, `(client, …)`, `(worker, …)`.

### Step 6 — Payments (Paymob) (1 hour)
1. `CommissionPayment(order OneToOne, amount, paymob_order_id,
   paymob_transaction_id, payment_key, payment_status)`.
2. `paymob.py` with `get_auth_token`, `create_paymob_order`, `get_payment_key`,
   `authorize_commission`, `capture_commission`, `void_commission`. Be
   defensive: 15-second timeouts, `raise_for_status`, structured logging.
3. `PaymobWebhookView` with HMAC-SHA512 verification using the documented
   field order. Reject with 403 on mismatch.
4. Wire env vars: `PAYMOB_API_KEY`, `PAYMOB_INTEGRATION_ID`,
   `PAYMOB_HMAC_SECRET`, `COMMISSION_AMOUNT`.

### Step 7 — Ratings + favorites (30 min)
1. `Rating(order OneToOne, client, worker, stars, review)` + validators.
2. On save, recompute `average_rating` of the worker.
3. `Favorite(client, worker)` with `unique_together`.
4. Public `/api/ratings/worker/<id>/` for reviews list.

### Step 8 — Notifications + FCM (45 min)
1. `Notification(user, title, message, type, is_read, data JSON)`.
2. `DeviceToken(user, token, platform, is_active)`.
3. `services.notify(user, title, message, type, data)` — single entry point,
   persists row + fans out via FCM if `FCM_SERVER_KEY` is set.
4. Endpoints: list, unread-count, mark read, mark all read, register/unregister
   device token.

### Step 9 — Cross-cutting hardening (30 min)
1. `core/permissions.py`: `IsClient`, `IsWorker`, `IsAdmin`,
   `IsOrderParticipant`. Use everywhere.
2. `core/throttling.py`: `AuthRateThrottle`, `OrderCreateThrottle`,
   `RatingThrottle` with env-tunable rates.
3. WhiteNoise for static.
4. `/api/health/` endpoint.
5. Tests: write at least one happy-path + one role-violation per app. Aim for
   ~30 tests minimum.

### Step 10 — Docker (45 min)
1. `Dockerfile`: Python 3.12-slim, install runtime libs (`libjpeg62-turbo`,
   `zlib1g`, `curl`, `gosu`), pip install, `collectstatic`, create `app` user,
   `HEALTHCHECK` against `/api/health/`.
2. `entrypoint.sh`: `chown` volumes, run migrations, exec gunicorn under `gosu app`.
3. `docker-compose.yml`: `web` service with `healthcheck`, named `sqlite_data`
   and `media_data` volumes.
4. `.dockerignore`: exclude `mobile/`, `.git/`, `.env`, IDE stuff.
5. `.env.example` — every var documented in sections.
6. `docker compose build && docker compose up -d` → wait for `(healthy)`.

### Step 11 — Mobile skeleton (30 min)
1. `flutter create mobile && cd mobile`.
2. `flutter pub add flutter_bloc dio shared_preferences intl flutter_svg`.
3. Set up theme (light/dark) and localizations (Arabic + English ARB).
4. `main.dart`: `await AppPrefs.init(); runApp(MultiBlocProvider(... MaterialApp(...)))`.

### Step 12 — Mobile core (1 hour)
1. `core/api/api_constants.dart` — every backend endpoint as a constant.
2. `core/api/api_client.dart` — Dio singleton, JWT injector, refresh on 401,
   wipe-on-failed-refresh.
3. `core/api/api_error.dart` — normalize Dio errors to a single user message.
4. `core/cache/json_cache.dart` — TTL SharedPreferences wrapper.
5. `core/validators.dart` — required, email, phone (regex matches backend).
6. `core/ui/snack.dart` — Snack.error/success/info.
7. `core/helpers.dart` (`AppPrefs`) — token + locale + theme keys.

### Step 13 — Mobile services + cubits (2 hours)
For each domain (auth, workers, orders, ratings, favorites, notifications):
1. Define a model class with `fromJson`.
2. Define a service class wrapping Dio, throwing `ApiError`.
3. Define a cubit + state classes.

### Step 14 — Mobile screens (3-4 hours)
1. Onboarding → Choose role → Register / Login.
2. MainScreen with bottom nav: Home / Orders / Favorites / Account.
3. HomeScreen: category filter chips + worker list.
4. WorkerDetailsView: profile + recent reviews + "book now" CTA.
5. CheckoutScreen: address + payment method.
6. OrdersScreen for clients vs RequistesScreen for workers (different filters).
7. JobHistory + Favorites + Account + Settings.

### Step 15 — End-to-end test (30 min)
1. `docker compose up -d`.
2. `flutter run -d linux` (or chrome).
3. Register one client + one worker.
4. Worker creates a profile.
5. Client books an order.
6. Worker accepts and completes it.
7. Client rates 5★.
8. Confirm rating shows on `/api/ratings/worker/<id>/`.

### Step 16 — Production checklist
- [ ] Real `DJANGO_SECRET_KEY` in your secrets manager
- [ ] PostgreSQL service in compose
- [ ] Redis for throttling cache
- [ ] FCM_SERVER_KEY filled in
- [ ] Paymob production credentials
- [ ] Reverse proxy (Nginx / Caddy) + TLS
- [ ] Object storage for media
- [ ] DB backups scheduled
- [ ] `DEBUG=False`, `CORS_ALLOW_ALL_ORIGINS=false`, explicit `ALLOWED_HOSTS`
- [ ] CI runs tests + builds image on every PR
- [ ] Mobile: real `https://api.your-domain` in `api_constants.dart`
- [ ] Mobile: switch JWT storage to `flutter_secure_storage`
- [ ] Crashlytics or Sentry wired

**Total realistic time from zero to a working dev build:** ~12-16 focused hours
for one developer who knows Django and Flutter. Add 2-3 weeks for production
hardening, real payments testing, and store submissions.

---

## 8. One-page summary

- **What:** Two-sided home-services marketplace, web of REST endpoints +
  Flutter mobile clients.
- **Stack:** Django 4.2 + DRF + JWT + (SQLite | PostgreSQL); Flutter 3.10 +
  BLoC + Dio + SharedPreferences; Docker.
- **Auth:** JWT with refresh; `IsClient` / `IsWorker` / `IsAdmin` permissions
  enforce roles centrally.
- **Money:** Cash between client and worker for the service price; Paymob
  charges only the platform commission via authorize-then-capture.
- **State:** Order moves through `PENDING → ACCEPTED → COMPLETED` (or
  `REJECTED` / `CANCELLED`).
- **Push:** Backend writes in-app rows always; sends FCM when `FCM_SERVER_KEY`
  is set.
- **Tests:** 32 backend tests + 10 mobile validator tests, all green.
- **Docker:** non-root, healthchecked, single-command boot, verified end-to-end.
- **Headroom:** Redis, PostgreSQL, FCM mobile wiring, real Paymob iframe,
  WebSocket order updates — all queued in §6 with concrete steps.
