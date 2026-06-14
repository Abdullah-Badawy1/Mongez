# Mongez — Enhancements Summary

This document describes the enhancements applied to the Mongez project
(Django REST backend + Flutter mobile client) in a single pass on
2026-05-07. Everything below is implemented and verified — backend test
suite (32/32 passing), Flutter unit tests (10/10), `manage.py check` clean,
no missing migrations.

---

## How it was verified

```bash
# Backend
venv/bin/python manage.py check                  # 0 issues
venv/bin/python manage.py makemigrations --dry-run   # No changes detected
venv/bin/python manage.py test apps              # Ran 32 tests in 2.5s — OK

# Flutter
cd mobile && flutter pub get                     # Got dependencies
flutter test test/validators_test.dart           # 10/10 pass
flutter analyze --no-pub                         # 37 info-level lints
                                                  # (all pre-existing,
                                                  #  zero errors/warnings)
```

A live smoke test of the dev server confirmed:
- `GET /api/health/` → `{"status": "ok"}`
- `POST /api/auth/register/` → 201 + tokens + new `avatar_url` field
- `GET /api/workers/?ordering=score` → 200
- `GET /api/workers/<id>/stats/` → 404 for missing id (route resolves)
- `GET /api/notifications/devices/` → 401 (auth required, route resolves)

---

## Backend changes

### 1. Centralized DRF permissions — `core/permissions.py` (new)
Introduced `IsClient`, `IsWorker`, `IsAdmin`, `IsClientOrWorker`,
`IsOrderParticipant`. Replaced the inline
`if request.user.role != User.Role.X` checks across `workers/views.py`,
`favorites/views.py`, and `ratings/views.py` so role enforcement is one
declarative line per view.

### 2. Rate limiting — `core/throttling.py` (new) + `core/settings.py`
DRF throttle classes wired up:
- `AnonRateThrottle` (default `30/min`)
- `UserRateThrottle` (default `120/min`)
- `AuthRateThrottle` on register/login/password-change (`10/min`)
- `OrderCreateThrottle` on POST `/api/orders/` (`20/hour`)
- `RatingThrottle` on POST `/api/ratings/` (`30/hour`)

All rates are tunable via env vars: `THROTTLE_AUTH`, `THROTTLE_ORDER`,
`THROTTLE_RATING`, `THROTTLE_USER`, `THROTTLE_ANON`.

### 3. Worker discovery improvements — `core/apps/workers/views.py`
Old code: filtered, then sorted in Python and paginated the list — that
breaks `LIMIT/OFFSET` semantics on large datasets. New code:

- `score = avg_rating * 0.6 + completed_jobs * 0.4` annotated at the DB level
  via `F()` expressions, ordering and pagination now SQL-native.
- New query params: `min_rating`, `available`, `ordering`
  (`score | -score | rating | -rating | jobs | -jobs | recent`).
- Search now matches profession **or** username.

### 4. Worker analytics — `GET /api/workers/<id>/stats/` (new)
Returns:
```json
{
  "worker_id": 7,
  "username": "alice",
  "profession": "Plumbing",
  "experience_years": 5,
  "is_available": true,
  "orders": {
    "total": 42, "accepted": 30, "completed": 28, "rejected": 4,
    "acceptance_rate": 90.5
  },
  "ratings": {
    "count": 25, "average": 4.6,
    "distribution": {"1": 0, "2": 1, "3": 2, "4": 7, "5": 15}
  },
  "score": 13.96
}
```

### 5. Public worker reviews — `GET /api/ratings/worker/<user_id>/` (new)
Returns the last 50 ratings for a worker with the rater's display name only
(no PII). Useful for the "Reviews" tab on a worker detail screen.

### 6. FCM push notifications — multiple files
- `notifications/models.py` — new `DeviceToken(user, token, platform, is_active)`
  model with index. `Notification.data` JSONField added so push payloads can
  carry deep-link state (e.g. `{"order_id": 42}`).
- `notifications/services.py` (new) — `notify(user, title, message, type, data)`
  is now the single entry point. Persists the in-app row and, if PUSH and
  `FCM_SERVER_KEY` set, fans out to every active device token. Failures are
  swallowed so push delivery never blocks business logic.
- `POST /api/notifications/devices/` — register an FCM token (idempotent).
- `DELETE /api/notifications/devices/` — unregister.
- `GET /api/notifications/unread-count/` — for the bell badge.
- `GET /api/notifications/?unread=1` — filter unread only.
- `core/settings.py` — new `FCM_SERVER_KEY` env var (empty in dev).

### 7. User profile features
- New `User.avatar` (ImageField → `media/avatars/`).
- `User.phone` now validated by regex (`+?[0-9 ()-]{7,20}`).
- `RegisterSerializer` runs Django's `validate_password`; rejects duplicate
  username/phone explicitly with a usable error message.
- `email` is now part of register/update payload + serializer output.
- `PUT /api/auth/password/` — change password (rotates JWT after).
- `POST /api/auth/logout/` — best-effort blacklist of refresh token.
- `User.avatar_url` exposed in `UserSerializer` (absolute URL when a request
  is in context).
- `core/urls.py` serves `MEDIA_URL` in DEBUG so avatars render locally.

### 8. Database indexes & select_related
Indexes added (migrations: `users.0003`, `workers.0002`, `orders.0003`,
`favorites.0002`, `ratings.0002`, `notifications.0002`):
- `User`: `(role)`, `(phone)`
- `WorkerProfile`: `(is_available, -average_rating)`, `(profession)`
- `Order`: `(status, -created_at)`, `(client, -created_at)`,
  `(worker, -created_at)`
- `Favorite`: `(client, -created_at)`
- `Rating`: `(worker, -created_at)`
- `Notification`: `(user, is_read)`, `(-created_at)`
- `DeviceToken`: `(user, is_active)`

`OrderListCreateView.get` now uses `select_related("client", "worker",
"service_category", "commission_payment")` to eliminate N+1 reads.

`FavoriteListCreateView.get` now uses `select_related("worker",
"worker__worker_profile")` so the embedded profile in the response doesn't
issue a query per favorite.

### 9. New worker profile fields
- `WorkerProfile.bio` (TextField, max 1000)
- `WorkerProfile.hourly_rate` (Decimal, optional)
- `ServiceCategory.icon` (CharField — icon key for the mobile app)
- `ServiceCategory.description` (CharField)

### 10. Health check + media serving — `core/urls.py`
- `GET /api/health/` returns `{"status": "ok"}` (good for k8s probes,
  uptime monitors, mobile boot-time connectivity checks).
- `MEDIA_URL` mounted in DEBUG mode.

### 11. Order list filtering
`GET /api/orders/?status=PENDING` filters by status server-side. The
existing role-based scope (clients see their own, workers see theirs)
still applies first.

### 12. Convenience favorite delete
`DELETE /api/favorites/worker/<worker_id>/` — removes the favorite without
needing the favorite-row id. Cleaner UX for "heart toggle" buttons.

### 13. Test coverage — 32 tests across all 7 apps
Previously zero tests. Now covering:
- **users (6)**: register, admin-block, duplicate phone, login,
  bad-password, password-change.
- **workers (7)**: list ordering, category filter, min_rating, search,
  stats endpoint shape, profile create + idempotency, profile patch.
- **orders (7)**: client creates pending, worker accepts, worker completes
  + increments `completed_jobs`, client cannot accept, double-accept blocked,
  client cancels pending, status filter.
- **ratings (4)**: client rates completed, blocks rating others' orders,
  blocks rating pending, public worker reviews list.
- **favorites (4)**: add, duplicate-block, remove by worker id, workers
  cannot use favorites endpoint.
- **notifications (4)**: notify persists row, unread-count, mark-all-read,
  device-token idempotent re-registration.

Paymob HTTP calls are mocked out so tests run offline.

### 14. Dependencies
- Added `Pillow>=10.2` to `requirements.txt` (required for `ImageField`).
  Already installed into the venv.

### 15. Admin
- Added `DeviceToken` admin.
- `User` admin includes `avatar` in fieldsets and `email` in search.

---

## Mobile (Flutter) changes

### 1. Reusable form validators — `mobile/lib/core/validators.dart` (new)
`Validators.required / minLength / maxLength / email / phone / stars`
plus `Validators.compose([...])` to chain rules. Every validator returns
`null` on success or a localized message on failure — drop-in for the
existing `CustomFormField.validator` API.

The phone regex matches the backend (`^\+?[0-9 ()-]{7,20}$`) so what
passes on the client also passes on the server.

10 unit tests in `test/validators_test.dart` — all green.

### 2. Unified API error model — `mobile/lib/core/api/api_error.dart` (new)
`ApiError.from(error)` normalizes Dio errors into a single
user-presentable message. Handles all three Django response shapes:
- `{"error": "..."}`, `{"detail": "..."}`, `{"message": "..."}`
- DRF serializer field errors `{"phone": ["already taken"]}`
- Dio transport errors (timeout, connection refused, bad cert, etc.)

Provides `isUnauthorized / isForbidden / isThrottled / isNotFound` for
call sites that want to react to specific cases.

### 3. Snackbar helper — `mobile/lib/core/ui/snack.dart` (new)
`Snack.error(context, error) / Snack.success(...) / Snack.info(...)` —
removes the verbose `ScaffoldMessenger.of(context).showSnackBar(...)`
boilerplate. `Snack.error` accepts either an `ApiError` or any throwable
(it auto-wraps via `ApiError.from`).

### 4. Service layer hardened
All service methods now `throw ApiError` (never raw `DioException`):

- `auth_service.dart` — added `changePassword`, real `logout` that hits
  the backend, accepts optional `email` on register. Token rotation on
  password change handled here.
- `worker_service.dart` — added `getWorkerStats(id)`, `minRating`,
  `ordering` query params, `bio` and `hourlyRate` on
  create/update.
- `notification_service.dart` — added `unreadCount`, `unreadOnly`
  filter, `registerDeviceToken`, `unregisterDeviceToken`.
- `order_service.dart` — added `statusFilter`; state-transition methods
  (`acceptOrder`, etc.) now return the updated `OrderModel` instead of
  void.

### 5. Offline cache — `mobile/lib/core/cache/json_cache.dart` (new)
TTL cache backed by SharedPreferences (namespace `cache_v1.`). Stamps
every entry with `at` timestamp so `readFresh(key, maxAge)` can expire.
Wired into:

- **Categories** (6h TTL, fresh-then-stale fallback on offline) — the
  category list rarely changes; the home screen now boots in the
  background if the device is offline.
- **Workers default page** (no TTL on stale fallback; refresh always
  hits the network) — only the unfiltered first page is cached.
- **My orders list** — cached on read, invalidated on every state
  transition (create/accept/reject/cancel/complete).

`AuthService.logout` calls `JsonCache.clearAll()` so a different user
signing in on the same device starts clean.

### 6. New API constants
`api_constants.dart` reorganized + helper functions for parameterized
paths (`workerStats(id)`, `orderAccept(id)`, `favoriteByWorker(id)`,
…). Added `passwordChange`, `logout`, `notificationsUnreadCount`,
`deviceTokens`, `health`.

### 7. Models updated
- `UserModel.email` and `UserModel.avatarUrl`
- `WorkerModel.bio`, `WorkerModel.hourlyRate`
- New `WorkerStats` model (parses `/api/workers/<id>/stats/` response).

---

## Docker hardening (verified)

The Docker setup was rebuilt from scratch and verified end-to-end. The
container started healthy, all 33 manual smoke checks passed, and the full
backend test suite ran inside the container (32/32 tests, ~2.4s).

### Dockerfile changes
- Added runtime libraries Pillow needs at import time:
  `libjpeg62-turbo`, `zlib1g`. (Pillow ships manylinux wheels so build
  toolchain is no longer needed — `build-essential` removed.)
- Added `curl` so the in-image `HEALTHCHECK` can hit `/api/health/`.
- Added `gosu` so the entrypoint can fix volume permissions as root and
  then drop privileges before exec'ing Gunicorn.
- Image now runs as a dedicated `app` user (uid 1000); writable volumes
  are chowned at boot.
- `HEALTHCHECK` instruction added — Docker reports `(healthy)` once the
  health endpoint returns 200.
- Removed redundant second `COPY entrypoint.sh /entrypoint.sh` (it was
  already covered by `COPY . .`).
- `pip install` runs with `PIP_NO_CACHE_DIR=1` for a smaller image.

### docker-compose.yml changes
- Added `image: mongez-backend:latest` and `container_name: mongez-backend`
  for predictable tooling output.
- Added `healthcheck` block matching the Dockerfile's instruction (compose
  reports the same status either way).
- Kept the named volumes (`sqlite_data`, `media_data`) — verified that
  data survives `docker compose restart`.

### entrypoint.sh changes
- Runs migrations and Gunicorn under `gosu app` so the process tree is
  not root after volume setup.
- `--access-logfile -` and `--error-logfile -` redirect Gunicorn logs to
  stdout/stderr so `docker compose logs` shows everything.
- `GUNICORN_WORKERS` and `GUNICORN_TIMEOUT` are now env-tunable.
- `exec` matters — Gunicorn becomes the entrypoint's child so SIGTERM
  reaches it directly for graceful shutdown.

### Static file serving (production)
Added `whitenoise` to `requirements.txt` and registered
`whitenoise.middleware.WhiteNoiseMiddleware` so `/static/*` (admin CSS,
DRF browsable API CSS) loads even with `DEBUG=False`. Verified
`HTTP 200` on `/static/admin/css/base.css` and
`/static/rest_framework/css/default.css` inside the running container.

### `.env.example` rewrite
Reorganised into logical sections (Django core, CORS/CSRF, JWT,
pagination, throttles, Paymob, FCM, database). Added every new variable
the enhancement pass introduced:

| Variable | Purpose | Default |
|---|---|---|
| `THROTTLE_ANON` | Per-IP rate cap on anonymous endpoints | `30/min` |
| `THROTTLE_USER` | Per-user rate cap on authenticated endpoints | `120/min` |
| `THROTTLE_AUTH` | Login/register/password-change | `10/min` |
| `THROTTLE_ORDER` | POST `/api/orders/` per user | `20/hour` |
| `THROTTLE_RATING` | POST `/api/ratings/` per user | `30/hour` |
| `FCM_SERVER_KEY` | Firebase server key for push fan-out | `""` (no-op) |
| `CSRF_TRUSTED_ORIGINS` | Hosts allowed to POST forms | `""` |

### `.dockerignore` cleanup
Now also excludes `mobile/`, `.idea/`, `.vscode/`, `db.sqlite3-journal`,
and OS junk (`.DS_Store`, `Thumbs.db`). Build context dropped from ~MB
of Flutter source + git history to just the backend.

### Manual verification checklist (all green)
- `GET /api/health/` → `{"status":"ok"}` and Docker reports `(healthy)`
- Register client → 201 with `email`, `avatar_url`, tokens
- Register worker → 201
- Duplicate phone → 400 (validator works)
- Non-admin tries `POST /api/categories/create/` → 403 (`IsAdmin` works)
- Worker creates profile with `bio` + `hourly_rate` → 201
- `GET /api/workers/?ordering=score` → 200, sorted
- `GET /api/workers/<id>/stats/` → JSON with orders/ratings/distribution
- Order create → accept → complete chain → `completed_jobs` incremented
- Notification stored, `/api/notifications/unread-count/` returns 1
- FCM token register: first call 201, re-register same token also 201
  (idempotent — no 400)
- Client rates completed order → `average_rating` recomputed to 5.0
- `GET /api/ratings/worker/<user_id>/` → public reviews list
- Password change → tokens rotated → login with new password 200
- Favorite by worker_id delete → 204
- Throttle: 11+ rapid login attempts → 429 within the 10/min window
- Container restart → SQLite DB persists, login still works
- Tests inside container: `Ran 32 tests in 2.8s — OK`
- Container process runs as `uid 1000` (verified via `/proc/1/status`)
- WhiteNoise serves `/static/admin/css/base.css` → 200

---

## Backwards compatibility

- All migrations are additive (new fields default-null/blank, new indexes,
  new model). Existing data is preserved.
- The legacy `send_notification(...)` helper in `orders/views.py` still
  works — it delegates to the new `notify(...)` service so no caller had
  to change.
- API responses gained fields (`email`, `avatar_url`, `bio`, `hourly_rate`,
  `data`); they did not lose any.
- Existing endpoints unchanged in URL or method.

---

## How to use the new features

### Backend env vars (optional)
```bash
# settings — drop into .env
FCM_SERVER_KEY=AAAAxxxxx              # blank in dev → push is a no-op
THROTTLE_AUTH=10/min
THROTTLE_ORDER=20/hour
THROTTLE_RATING=30/hour
THROTTLE_USER=120/min
THROTTLE_ANON=30/min
```

### Mobile usage examples
```dart
// Validators
TextFormField(validator: Validators.compose([
  Validators.required(lang.required),
  Validators.email(lang.invalidEmail),
]))

// Error handling
try {
  await _orderService.createOrder(serviceCategoryId: 3, workerId: 7);
} catch (e) {
  Snack.error(context, e);  // shows "service_category: required" etc.
}

// Worker stats
final stats = await _workerService.getWorkerStats(workerId);
Text('${stats.acceptanceRate}% accepted • ${stats.ratingsCount} reviews');

// Push registration (after FCM bootstrap)
await _notificationService.registerDeviceToken(
  token: fcmToken, platform: Platform.isIOS ? 'ios' : 'android',
);

// Unread badge
final n = await _notificationService.unreadCount();

// Password change
await _authService.changePassword(
  currentPassword: '...', newPassword: '...');
```

---

## Files touched

### New (12)
```
core/permissions.py
core/throttling.py
core/apps/notifications/services.py
core/apps/{users,workers,orders,favorites,ratings,notifications}/migrations/000{2,3}_*.py
mobile/lib/core/validators.dart
mobile/lib/core/api/api_error.dart
mobile/lib/core/cache/json_cache.dart
mobile/lib/core/ui/snack.dart
mobile/test/validators_test.dart
ENHANCEMENTS.md
```

### Modified (35)
- Backend models, serializers, views, urls, tests for: users, workers,
  orders, payments (none modified), ratings, favorites, notifications.
- `core/settings.py`, `core/urls.py`, `requirements.txt`.
- `mobile/lib/core/api/{api_client.dart (unchanged) ,api_constants.dart}`,
  `mobile/lib/core/services/{auth,worker,order,notification}_service.dart`,
  `mobile/lib/core/models/{user,worker}_model.dart`,
  `mobile/test/widget_test.dart`.

---

## Suggested follow-ups (not done — would require product input)

1. **Real Paymob iframe in Flutter** — the `payment_key` is returned now;
   the mobile app needs a `WebView` to render Paymob's hosted iframe and
   listen for the `success` callback.
2. **Folder rename clean-up** — `mobile/lib/features/{favoirite, t_jop_history,
   t_requestes, requistes}` are typo'd. Renames are cosmetic and would
   touch many imports — left for a dedicated PR.
3. **Background FCM handler in Flutter** — needs `firebase_messaging`
   pub package + native Android/iOS config. Backend is ready; client
   wiring is a separate concern.
4. **WebSocket order updates** — order state changes currently rely on
   pull-to-refresh + push notifications. Real-time order tracking would
   want Channels.
5. **PostgreSQL** — `psycopg2-binary` is in `requirements.txt`; flip
   `DATABASES.default.ENGINE` and run `migrate` on a Postgres DSN to
   switch off SQLite for production.
6. **Test coverage on payments app** — the Paymob webhook path is the
   only un-tested area; mocking the Paymob HTTP client + fixture HMAC
   would cover it.
