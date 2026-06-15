# Mongez — Professional-grade Engineering Guide

A single document that does two things:

1. **Catalogs what's already in place** across the backend, dashboard and
   mobile — and explains *why* each choice is the professional one.
2. **Lists what I'd add next** to take the app from "ships and works"
   to "production-grade at scale" — ordered by impact-per-effort so you
   can pick off the top of the list and stop when you've spent your
   budget.

If you only read one section, read the **TL;DR** at the bottom.

---

## 1. The platform at a glance

Three runtime surfaces, one Django REST API as the single source of truth:

```
                          ┌────────────────────────────┐
                          │  Django REST  /api/         │
                          │  (Gunicorn × 2 in Docker)   │
                          │  apps/users   apps/workers  │
                          │  apps/orders  apps/payments │
                          │  apps/ratings apps/favorites│
                          │  apps/notifications         │
                          │  apps/admin_api ← dashboard │
                          └─────┬───────────────┬───────┘
              JSON / JWT        │               │       JSON / JWT
                                │               │
        ┌───────────────────────┘               └─────────────────────┐
        ▼                                                             ▼
  React + Vite SPA (front/)                              Flutter app (mobile/)
  Landing + Admin Console                                Client / Worker
  • usePolling, optimistic updates                       • Cubits + Dio
  • 27 Egyptian governorates dropdown                    • 30 s order/notification poll
  • ESLint, hot build                                    • i18n ar/en, theme switch
```

Persistence: SQLite (Docker named volume). Uploaded files: media volume.
Paymob handles platform commission only — clients pay workers in cash.

For an architectural deep-dive see [`all.md`](all.md) and
[`docs/ARCHITECTURE.puml`](docs/ARCHITECTURE.puml).

---

## 2. What's already professional (and why)

### 2.1 Backend (`core/`)

| Practice | Where | Why it matters |
|---|---|---|
| **DRF + SimpleJWT** with access + refresh tokens, auto-rotation, and a per-endpoint throttle scope (`AuthRateThrottle`, `OrderCreateThrottle`, `RatingThrottle`). | `core/settings.py`, `core/throttling.py` | Standard, audited security primitives. Easy to harden later (lower the rates, add IP throttling) without touching app code. |
| **Permission classes per role**: `IsClient`, `IsWorker`, `IsAdmin`, `IsOrderParticipant`. | `core/permissions.py` | The role gate is in *one* place per role — every view that should be client-only just lists `IsClient`. New endpoint, one line, no copy-paste mistakes. |
| **No Django admin** — purely REST. | `core/urls.py` | Eliminates a whole class of risk (CSRF on `/admin/`, leaked staff accounts, the wrong person modifying production data through the UI). The React dashboard is the only management surface. |
| **Migrations are linear and clean**; `makemigrations --dry-run` reports no changes. | `core/apps/*/migrations/` | Reproducible deploys. Anyone cloning the repo gets identical schema. |
| **Cached aggregate** on `/api/admin/dashboard/` (5 s TTL). | `apps/admin_api/views.AdminDashboardView` | N admins polling at 10 s each cost at most one DB query every other tick. Pre-empts the "dashboard is slow" complaint. |
| **Single source of truth** for static lists: governorates live in `apps/users/governorates.py`, served by `/api/governorates/`. | | One JSON shape consumed by both mobile and dashboard. Add a governorate → it shows up everywhere on next page-load. |
| **Notification fan-out** on every state-changing admin action (order status PATCH, rating create). | `apps/admin_api/views.AdminOrderStatusView`, `apps/ratings/serializers.RatingSerializer.create` | Mobile users see updates through two independent channels (order-list poll + notification-cubit poll + optional FCM push), so a slow poll never leaves them in the dark. |
| **Tests** — 48 of them, run with `python manage.py test apps`. CI-friendly. | `core/apps/*/tests.py` | Regression cover for the real bug classes the app has hit (admin role gate, register field shape, worker create category_id ↔ profession mapping, rating notify fan-out). |
| **Friendly error messages** — `"Username can't contain spaces. Use letters, numbers, or _"` instead of Django's opaque `UnicodeUsernameValidator` default. | `apps/users/serializers.RegisterSerializer` | End-user feedback that survives translation; saves a ticket per friendly message. |

### 2.2 Dashboard (`front/`)

| Practice | Where | Why it matters |
|---|---|---|
| **Modern toolchain**: React 19 + Vite 7. | `front/package.json` | Sub-second HMR; build under 2 s; no Webpack bloat. |
| **Generic `usePolling` hook** with `document.visibilitychange` listener. | `front/src/hooks/usePolling.js` | One implementation pauses on tab-hidden, refires on tab-return — every page gets it for free. Saves bandwidth, saves backend CPU. |
| **Optimistic updates** on the action that drives the mobile (`/admin/orders/<id>/status/`). | `front/src/pages/admin/Orders.jsx` | Admin clicks "Accepted" → row flips instantly. PATCH happens in the background; reverts on failure. Two-second hot path feels like zero. |
| **"Updated X s ago"** freshness badge + manual refresh button on every admin page. | `front/src/hooks/usePolling.useTimeAgo` | Eliminates the "is this fresh?" anxiety. Admins know if they need to click. |
| **Dev proxy** for `/api` and `/media` to `127.0.0.1:8000`. | `front/vite.config.js` | The browser never has to think about CORS in dev. Production deploys the bundle behind the same origin as the API. |
| **ESLint** at zero errors with React hooks + react-refresh rules. | `front/eslint.config.js` | Bugs like `motion is not defined` (the one that caused the white-screen earlier) get caught before commit when running locally. |

### 2.3 Mobile (`mobile/`)

| Practice | Where | Why it matters |
|---|---|---|
| **Clean architecture per feature**: each feature has `data/`, `domain/`, `presentation/`. | `mobile/lib/features/*/` | Repository tests don't need a Flutter widget tree. Easy to swap backends or mock for tests. |
| **Cubit per use-case** (orders, notifications, workers, profile, …) registered globally and reset on logout. | `mobile/lib/main.dart`, `services/navigation_service.dart` | One central place to wipe state on account switch. No stray cache leaking the previous user's data. |
| **30 s polling on the right cubits**: `NotificationCubit`, `CustomerOrdersCubit`, `TechnicianOrdersCubit`, `WorkerStatsCubit`. | `features/notifications/.../notification_cubit.dart` and others | Backend-driven updates (admin status PATCH, a new client order, a fresh rating) propagate without WebSockets. |
| **Optimistic toggles** on `is_available`. | `WorkerStatsCubit.toggleAvailability` | The switch feels instant. Reverts to the previous value on API error. |
| **Service locator** (`get_it`) bootstraps every repo / api client once. | `mobile/lib/services/services_locator.dart` | Cubits don't need to know how their repos are built; tests can override. |
| **In-process cache** for `/api/categories/` and `/api/governorates/`. | `features/home/repos/home_repo_implementation.dart`, `features/auth/repos/governorates_repo.dart` | Avoids the "spinner on every screen open" feeling for lists that change once a month. |
| **i18n with `ar` + `en`** and a dedicated `LocalizationCubit`. | `core/bloc/cubit/localization_cubit.dart` | Arabic-first product can ship Arabic strings as easily as English. Right-to-left flipping handled by `Directionality.of(context)`. |
| **Inter font + brand palette mirrored from the dashboard** so the mobile and the web share an identity. | `core/app_themes.dart`, `core/app_colors.dart` | A user that signs in on both surfaces sees the same brand. |
| **Defensive back-pop**: cubit references captured in `didChangeDependencies()` so `dispose()` never touches `context`. | `customer_requests_screen`, `technician_requests_screen`, `edit_profile_screen`, `worker_home_screen` | The "back button freezes the app" symptom is dead by construction. |

---

## 3. What to add next, ordered by impact ÷ effort

Each row has the *outcome*, the *effort* (S/M/L), and the *why*.
Pick from the top; stop when you're out of budget.

### 3.1 High impact / Low effort — do these next

1. **CI pipeline** — *S effort, high payoff.*
   Run `manage.py test apps`, `npm run lint && npm run build`, and
   `flutter analyze && flutter test` on every PR via GitHub Actions.
   Branch protection blocks merges on red.
   *Why:* the dashboard white-screen bug, the admin_api `category` 500,
   the `profession` field-required bug — every regression we hit this
   week would have been caught by CI before it reached you.

2. **Sentry on all three surfaces** — *S effort.*
   `sentry-sdk[django]` on backend, `@sentry/react` on dashboard,
   `sentry_flutter` on mobile. ~30 minutes per surface.
   *Why:* you'll know about a crash *before* the user emails. The
   logs include the Dart stack frame, the request ID, and the user's
   role. Free tier is enough for a small app.

3. **`drf-spectacular` for OpenAPI** — *S effort.*
   Auto-generates the API schema from the serializers + views you
   already have. Adds `/api/schema/` and `/api/docs/`.
   *Why:* the only canonical API reference today is `API_links.md`,
   which drifts. With spectacular it can't drift — the schema *is*
   the code. Useful for onboarding new mobile/dashboard devs.

4. **Secret rotation discipline** — *S effort.*
   - Add `python-dotenv` `--strict` so the app refuses to boot if a
     `DJANGO_SECRET_KEY` shorter than 50 chars is detected.
   - Rotate the dev `.env` example to use placeholders only
     (already done) and document the production rotation cadence in
     `INSTALL.md`.
   *Why:* the single biggest production risk for a Django app is a
   leaked SECRET_KEY allowing session forgery. Hard to leak a value
   that you've never put in git history.

5. **Pre-commit hooks** — *S effort.*
   `pre-commit` with `ruff` (backend), `eslint --fix` (dashboard),
   `flutter format` (mobile). Runs on staged files.
   *Why:* stylistic noise lands in PRs as actual code review noise.
   The robot fixes it; the human reviews logic.

6. **Backup the SQLite volume on a cron** — *S effort.*
   `docker compose exec -T web cp /app/data/db.sqlite3 /app/media/backup-…sqlite3`
   on a host-level cron + rotation. Two-line shell script.
   *Why:* the platform's *only* source of truth is one file. A
   container restart with the wrong volume args today would be a
   silent total wipe.

### 3.2 Medium impact / Medium effort — schedule these next quarter

7. **Move SQLite → PostgreSQL** for production. *M effort.*
   `psycopg[binary]` + `dj-database-url`. Update
   `docker-compose.yml` with a `db` service.
   *Why:* concurrent writes don't deadlock; FTS exists; Django's
   PostgreSQL backend has things like array fields that simplify
   `specialties_list` (currently a CSV column).

8. **Replace polling with Django Channels + Redis** *for the order
   status & notification surfaces.* *M-L effort.*
   Keep the polling code as a fallback for clients that disconnect.
   *Why:* the dashboard polls every 10 s; the mobile every 30 s.
   With sockets a status flip lands in under a second. Bandwidth
   drops drastically (no polling on idle tabs / backgrounded apps).
   The architecture in [`all.md` §8](all.md) already lays out where
   the seam goes — we just plug an ASGI server in front of Gunicorn.

9. **Sentry Performance + Trace context** — *M effort.*
   Once basic Sentry is in, enable the performance product. Each
   admin action ends up traced backend → frontend → mobile so you
   can see *where* a slow click is slow.

10. **Dashboard code-splitting** — *M effort.*
    `vite-plugin-dynamic-import` or manual `React.lazy` for each
    admin page. Right now the bundle is 640 KB → ≈ 200 KB gzipped
    but on a slow phone the FCP is 1.5 s.
    *Why:* the admin console is loaded by a handful of people; the
    landing page by everyone. Today a casual visitor downloads the
    full admin JS for nothing. Split → landing serves only what it
    needs.

11. **Mobile crash & analytics: Firebase Crashlytics + Mixpanel
    (or PostHog)** — *M effort.*
    Hook into the existing `Cubit` lifecycle to log `cubit_change`
    events.
    *Why:* you'll know which features actually get used. "Workers
    rarely tap the recent-reviews list" is the kind of insight that
    drives the next sprint.

12. **drf-spectacular → typed clients** — *M effort.*
    Once the schema exists, run `openapi-typescript-codegen` to
    generate a typed axios client for the dashboard, and
    `openapi-generator` for a typed Dio client on mobile. Delete
    the hand-written endpoint constants.
    *Why:* every `category_id` vs `profession` mismatch we've hit
    becomes a compile-time error rather than a 400 in production.

13. **Pagination on `/api/orders/`** for clients with many orders.
    *S-M effort.* Move from "return everything" to DRF's
    `PageNumberPagination` with `page_size=20`. Mobile reads
    `next` from the response.
    *Why:* we already paginate `/api/admin/users/` and `/api/admin/workers/`.
    A client with a year of orders is the same scaling problem.

### 3.3 High impact / High effort — keep on the radar

14. **Offline-first mobile** with Hive / Drift. *L effort.*
    Cache orders + notifications locally; sync deltas when network
    returns.
    *Why:* Egypt has plenty of 3G dead zones; an order placed on
    spotty signal currently fails outright. Offline-first turns it
    into "queued, syncing later".

15. **Real FCM push** (or Apple Push for iOS) wired end-to-end.
    *L effort.* Backend already calls `_push_to_devices` — but the
    mobile app doesn't yet request FCM tokens and register them.
    A few config files + one `DeviceToken` POST on app start.
    *Why:* eliminates the 30 s polling gap entirely for
    user-facing notifications. Battery friendly.

16. **Multi-tenant or per-region deploys**, with a `Region` model
    above `Governorate`. *L effort.*
    Useful if Mongez ever ships to Saudi / UAE.

17. **Infrastructure as code** — Terraform/Ansible for whichever
    VPS you deploy on. *L effort.*
    *Why:* "the server is gone, restore it" today is a manual
    process. With IaC it's `terraform apply`.

18. **Penetration test by a third party** before going public.
    *L effort, hard to skip.*

---

## 4. Specific suggestions per surface

### 4.1 Backend hardening checklist

- [ ] Set `SECURE_HSTS_SECONDS=31536000` + `SECURE_SSL_REDIRECT=True`
      in production settings. Already configurable via env.
- [ ] Add `Content-Security-Policy` via `django-csp` (or via the
      reverse proxy you put in front of Gunicorn).
- [ ] Wrap the Paymob webhook endpoint with a constant-time HMAC
      comparison helper — currently uses `hmac.compare_digest` which
      is fine; verify in tests.
- [ ] Validate **all** `phone` inputs against the existing regex
      (the User model already does, but no test asserts a 400 on a
      malformed phone during register).
- [ ] Add a feature flag (`waffle` or a simple env var) for the
      next risky migration so you can toggle without a code deploy.

### 4.2 Dashboard polish

- [ ] **ErrorBoundary** around `<AppRoutes/>` so a runtime exception
      in one admin page doesn't blank the whole app (today it does;
      see the white-screen postmortem).
- [ ] **Accessibility pass** — every clickable `div` should be a
      `button`. The dashboard is mostly OK but a screen reader test
      with Lighthouse highlights tab-trap issues in the Add User
      modal.
- [ ] **Skeleton loaders** instead of spinners on first paint of
      each admin page. The data is already cached server-side; the
      animation just stops feeling laggy.
- [ ] **Storybook** for the design system primitives
      (`Button`, `Table`, `StatsCards`). Useful when more than one
      developer is touching the UI.
- [ ] **Vitest + React Testing Library** smoke tests on the auth
      flow + the admin Orders status flip. We have curl coverage of
      the API; we should have widget coverage of the SPA.

### 4.3 Mobile

- [ ] **Replace `setState` in long-lived screens with cubits.** A
      few screens (notably the older `details` views) still use
      local state where a cubit would be cleaner.
- [ ] **Constant-time JWT refresh** — at 401 the Dio interceptor
      retries via `/auth/token/refresh/`. Fine. Add a debounce so
      two parallel 401s don't fire two refresh requests.
- [ ] **Empty-state illustrations** in the worker home / requests
      screens. Today we use Material icons; a small set of branded
      SVGs makes the empty states feel less "developer".
- [ ] **Golden tests** for the worker home and the register screen.
      Flutter has `flutter_test`'s `goldenFileComparator`; one
      reference PNG per screen catches accidental layout drift.
- [ ] **End-to-end integration tests with `patrol`.** Drives a real
      Android emulator through register → place an order →
      accept on a second emulator → rate. Painful to set up;
      golden once it works.

---

## 5. Concrete acceptance criteria for "production-ready"

If you want a checklist to print and walk through before going live:

```
□  CI green on a PR that just adds a print()        (smoke)
□  Sentry receives a deliberate exception            (wiring)
□  /api/schema/ renders via drf-spectacular          (docs)
□  Postgres replacing SQLite                         (durability)
□  Daily automated backup of the production volume   (DR)
□  HTTPS, HSTS, CSP confirmed on the deploy URL      (security)
□  A red-team rate-limit test (>1000 logins/min)
   returns 429 from the throttle scope               (security)
□  The worker home loads in under 2 s on a
   throttled 3G connection (Chrome DevTools)         (perf)
□  Every admin action lands in the mobile in under
   3 s via the headless E2E probe                    (UX)
□  A staging environment with prod-like data         (release)
□  An incident runbook for "API is down"             (ops)
```

---

## 6. TL;DR

- The codebase already does the **non-negotiables** for a professional
  REST app: role-based permissions, JWT + throttling, per-page admin
  cache, polling with visibility-pause, optimistic admin actions,
  Notification fan-out so the mobile never relies on a single channel,
  cubit lifecycle that prevents back-pop crashes, ESLint at zero,
  48 passing backend tests, and ~26 mobile lints that are all info-level.

- The **single most valuable next step** is wiring CI (GitHub Actions
  running the existing test commands) and Sentry on all three surfaces.
  Together they are about an afternoon of work and they prevent the
  majority of "user found a bug before I did" outcomes.

- After that: move from SQLite to PostgreSQL, swap polling for
  Channels on the hot order-status path, and add `drf-spectacular`
  so the API schema generates typed clients for both the dashboard
  and the mobile. Each one of those is one or two days and each
  one closes a class of bug.

- **Don't bother** prematurely with microservices, GraphQL, a
  separate iOS swift codebase, or a custom CSS framework. The app
  has none of the scale signals that justify any of those.

- **Always benchmark before you change perf**: the polling cadence
  we have is *already* fast enough for the current load. Don't add
  WebSockets to look modern — add them when polling actually hurts.

If you only ship one new thing this week, ship GitHub Actions.
If you only ship one this month, ship Sentry.
If you only ship one this quarter, ship PostgreSQL + drf-spectacular.

That order is the *senior* answer — biggest reduction in real-world
risk first, lowest cost, no new architecture surface.
