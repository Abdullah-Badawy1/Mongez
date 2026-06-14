# Mongez — Cloud Services Guide

What you actually need from a cloud provider to put Mongez in front of real
users, in three tiers — **must-have**, **should-have**, **nice-to-have** — with
concrete options, ballpark costs, and the exact code/config wiring for *this*
codebase. Not a generic checklist.

> Companion documents:
> - [`PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md) — what the app *is*
> - [`INSTALL.md`](INSTALL.md) — how to run it locally
> - [`DOCKER_VERIFICATION.md`](DOCKER_VERIFICATION.md) — container smoke-test
> - [`ENHANCEMENTS.md`](ENHANCEMENTS.md) §6 lists improvement items that map to
>   several services here.

---

## 0. Production architecture in one picture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              END USERS                                       │
│   Android phone │ iOS phone │ Web (mobile)                                   │
└────┬───────────────────┬───────────────────┬────────────────────────────────┘
     │ HTTPS             │ HTTPS             │ HTTPS
     ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────┐    ┌──────────┐
│  CDN + DNS + TLS  (Cloudflare / CloudFront)                 │◀──▶│  DOMAIN  │
└────────────────────────────┬────────────────────────────────┘    │ REGISTRAR│
                             │                                      └──────────┘
                             ▼
                   ┌───────────────────┐
                   │  Reverse proxy    │   (Cloudflare → origin, or
                   │  (or app gateway) │    AWS ALB, Caddy, Nginx)
                   └─────────┬─────────┘
                             │
              ┌──────────────┼──────────────────────────┐
              │                                          │
              ▼                                          ▼
   ┌─────────────────────┐                  ┌─────────────────────────┐
   │  COMPUTE            │                  │  STATIC + MEDIA         │
   │  Django container   │                  │  (S3 / R2 / Spaces)     │
   │  on Cloud Run /     │                  │  fronted by the CDN     │
   │  ECS Fargate /      │                  └─────────────────────────┘
   │  Fly.io …           │
   └─────────┬───────────┘
             │
   ┌─────────┼──────────────────────────────────┬────────────────────┐
   │         │                                  │                    │
   ▼         ▼                                  ▼                    ▼
┌──────┐  ┌──────┐   ┌──────────┐   ┌────────────────┐  ┌──────────────────┐
│ DB   │  │REDIS │   │ EMAIL    │   │  PAYMOB        │  │  FIREBASE        │
│ (PG) │  │      │   │ (SES /   │   │  (Egypt)       │  │  Cloud Messaging │
│ RDS… │  │ Up-  │   │ SendGrid)│   │  authorize +   │  │  (Android/iOS/Web│
│      │  │stash │   │          │   │  capture +     │  │  push)           │
└──────┘  └──────┘   └──────────┘   │  void          │  └──────────────────┘
                                    │  webhook       │
                                    └────────────────┘
                                            │
                                            ▼
                                    POST /api/payments/webhook/
                                    (HMAC-verified)

┌─────────────────────────────────────────────────────────────────────────────┐
│  CROSS-CUTTING                                                              │
│  Sentry (error tracking)   ·   GitHub Actions (CI/CD)   ·   Docker registry │
│  (GHCR/ECR/Docker Hub)     ·   Secrets manager (Doppler/AWS SM/Vault)       │
│  Logs (Datadog/Better Stack/Grafana Loki)   ·   Backups (provider-native)   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Must-have services (the app cannot ship without these)

### 1.1 Compute / container hosting

**Why:** Django + Gunicorn must run somewhere reachable from the public internet.

| Provider | Plan | Strengths | Cost (rough) | Best for |
|---|---|---|---|---|
| **Google Cloud Run** | Pay-per-request | Auto-scales to zero, container-native, simplest deploy | $0–$30/mo light traffic | MVPs, bursty traffic |
| **AWS ECS Fargate** | Pay-per-task | Mature, deep AWS integration, ALB/Route53 native | $30–$100/mo (1 task always-on) | Teams already on AWS |
| **AWS App Runner** | Pay-per-request | Simpler than ECS, container-native | $30–$80/mo | Small teams on AWS |
| **DigitalOcean App Platform** | $5–$25/mo per service | Cheap, predictable, very simple UI | $12/mo (basic) | Solo builders |
| **Fly.io** | $0–$20/mo | Edge regions, free TLS, super fast deploys | ~$15/mo (1 shared CPU) | Small global apps |
| **Railway** | $5/mo + usage | Heroku-style DX, GitHub-driven | ~$15–$30/mo | Quick start |
| **Render** | $7/mo per service | Heroku-like, fewer footguns | $7–$25/mo | MVPs |

**Wiring:** the project already ships a production-ready `Dockerfile` and
`docker-compose.yml`. Most providers above accept either the image (push to
their registry) or build it from your repo. Set the env vars from
`.env.example` in the provider's dashboard. Expose port 8000.

**Recommendation for Mongez today:** **DigitalOcean App Platform** ($12/mo) or
**Fly.io** (~$15/mo) — both are one-command deploys from this repo and won't
overwhelm a solo team with AWS console complexity. Move to Cloud Run or
Fargate when you outgrow that.

### 1.2 Managed PostgreSQL

**Why:** SQLite is fine in the dev container but cannot serve concurrent users
safely. `psycopg2-binary` is already in `requirements.txt`.

| Provider | Plan | Strengths | Cost |
|---|---|---|---|
| **AWS RDS** | db.t4g.micro | Mature, automated backups, multi-AZ option | $15–$40/mo single-AZ |
| **Google Cloud SQL** | db-f1-micro | Tight Cloud Run integration | $9–$25/mo |
| **DigitalOcean Managed DB** | $15/mo dev plan | Simple UI, free daily backups | $15/mo |
| **Supabase** | $0 free tier, $25 pro | PostgreSQL + REST + auth + storage in one | $0–$25/mo |
| **Neon** | $0 free, $19 pro | Serverless PG, branching, scales to zero | $0–$19/mo |
| **Railway PG** | $5/mo + usage | Bundled with their compute | ~$10/mo |

**Wiring:** add `dj-database-url` to `requirements.txt`, then in
`core/settings.py`:

```python
import dj_database_url

DATABASES = {
    "default": dj_database_url.config(
        default=os.getenv("DATABASE_URL", "sqlite:///db.sqlite3"),
        conn_max_age=600,
        ssl_require=os.getenv("DB_SSL", "true").lower() == "true",
    )
}
```

Then set `DATABASE_URL` in your provider's env to the connection string they
give you (`postgres://user:pass@host:5432/dbname`).

**Migration plan:** export your dev SQLite data with
`python manage.py dumpdata > seed.json`, then on prod run
`python manage.py migrate && python manage.py loaddata seed.json`.

### 1.3 DNS + TLS + domain

**Why:** mobile apps cannot ship with `http://` in production (Apple ATS,
Android cleartext rules) and end users won't trust an IP.

| Provider | Strengths | Cost |
|---|---|---|
| **Cloudflare** | Free TLS, free CDN, free DNS, DDoS protection | $0 + ~$10/yr domain |
| **AWS Route 53 + ACM** | Tight AWS integration, ACM certs free | $0.50/mo per zone + $10/yr domain |
| **Namecheap / Porkbun** | Cheap registration, basic DNS | $8–$12/yr |

**Wiring:** point your domain at the compute provider's DNS target. Update
`DJANGO_ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS` in `.env`. In the Flutter app,
edit `mobile/lib/core/api/api_constants.dart`:

```dart
static const String baseUrl = 'https://api.your-domain.com/api/';
```

**Recommendation:** **Cloudflare** for everything (DNS + TLS + CDN + WAF) — it's
free for what you need and the dashboard is pleasant.

### 1.4 Push notifications — Firebase Cloud Messaging

**Why:** the backend already supports FCM (`apps/notifications/services.py`
fan-out is wired and tested). Without this, workers don't get a buzz when a
new order arrives — they have to refresh manually.

| Provider | Plan | Strengths | Cost |
|---|---|---|---|
| **Firebase Cloud Messaging** | Always free | Works for Android, iOS, Web | $0 |

**Backend wiring (already done in this project):**
- `core/settings.py` reads `FCM_SERVER_KEY`.
- `notify(...)` in `apps/notifications/services.py` POSTs to FCM HTTP API.
- Set `FCM_SERVER_KEY` in your prod `.env` from
  Firebase Console → Project Settings → Cloud Messaging.

**Mobile wiring (still TODO — see `ENHANCEMENTS.md` §6.2):**
1. `flutter pub add firebase_core firebase_messaging`
2. Add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) to
   the mobile app.
3. In `main.dart`:
   ```dart
   await Firebase.initializeApp();
   final fcmToken = await FirebaseMessaging.instance.getToken();
   if (fcmToken != null) {
     await NotificationService().registerDeviceToken(token: fcmToken);
   }
   ```
4. Handle foreground messages with `FirebaseMessaging.onMessage.listen(...)`.

### 1.5 Payment gateway — Paymob

**Why:** the platform's only revenue stream is the per-order commission. The
backend's Paymob client (`apps/payments/paymob.py`) is fully implemented and
HMAC-verified. You only need real credentials.

| Provider | Why Paymob? | Cost |
|---|---|---|
| **Paymob** | Local Egyptian provider, supports authorize + capture + void | per-transaction fee |

**Wiring (already done in this project — needs production credentials):**
1. Sign up at https://paymob.com → register a merchant account.
2. Copy from Paymob Dashboard:
   - `PAYMOB_API_KEY` — Settings → Account → Profile
   - `PAYMOB_INTEGRATION_ID` — Developers → Integrations → "Online Card"
   - `PAYMOB_HMAC_SECRET` — Developers → Account → HMAC
3. In Paymob Dashboard → Developers → Notifications, register your callback:
   `https://api.your-domain.com/api/payments/webhook/`.
4. Set those three env vars in production. Test with a Paymob sandbox card.

**Mobile wiring (still a stub — see `ENHANCEMENTS.md` §6.5):**
After `POST /api/orders/`, the response includes a `payment_key`. Render
Paymob's iframe inside a Flutter `WebView`:

```dart
final url =
  'https://accept.paymob.com/api/acceptance/iframes/$INTEGRATION_ID'
  '?payment_token=$paymentKey';
WebViewWidget(controller: WebViewController()..loadRequest(Uri.parse(url)));
```

### 1.6 App stores (mobile distribution)

**Why:** that's how end users install the app.

| Store | One-time cost | Annual cost | Review time |
|---|---|---|---|
| **Google Play Console** | $25 once | $0 | 1–7 days first time |
| **Apple App Store Connect** | $0 | $99/yr | 1–3 days typically |

**Wiring:**
1. Bump `version` and `+build` in `mobile/pubspec.yaml`.
2. `flutter build appbundle --release` → upload `.aab` to Play Console.
3. `flutter build ipa --release` → submit via Xcode / Transporter.
4. For private beta: **Firebase App Distribution** (free) or **TestFlight**
   (Apple) — both let internal testers install without a public listing.

---

## 2. Should-have services (real users will hit edges without these)

### 2.1 Redis — caching + throttling

**Why:** `ENHANCEMENTS.md` §6.3 calls this out — DRF's default rate-limit
cache is per-process, so with 2 Gunicorn workers a determined attacker
effectively gets 2× the configured limit. Redis fixes this in 30 lines of
config.

| Provider | Plan | Strengths | Cost |
|---|---|---|---|
| **Upstash Redis** | $0 free tier, $10/mo pro | Per-request pricing, true serverless | $0–$10/mo |
| **AWS ElastiCache** | cache.t4g.micro | AWS-native, predictable | $11/mo |
| **Google Memorystore** | Basic 1 GB | GCP-native | $35/mo (overkill for throttle cache) |
| **DigitalOcean Managed Redis** | $15/mo | Simple, single-cluster | $15/mo |
| **Railway Redis** | $5/mo + usage | Bundled with compute | ~$8/mo |

**Wiring:**
1. `pip install django-redis` (add to `requirements.txt`).
2. In `core/settings.py`:
   ```python
   CACHES = {
       "default": {
           "BACKEND": "django_redis.cache.RedisCache",
           "LOCATION": os.getenv("REDIS_URL", "redis://127.0.0.1:6379/1"),
           "OPTIONS": {"CLIENT_CLASS": "django_redis.client.DefaultClient"},
       }
   }
   ```
3. Set `REDIS_URL` env var to the connection string.
4. DRF throttling auto-uses the default cache backend — no other change.

**Recommendation:** **Upstash** — generous free tier and pay-per-request scales
naturally with the app.

### 2.2 Object storage — avatars + future media

**Why:** today `media_data` is a local Docker volume. On Cloud Run / Fargate,
that volume is **ephemeral** — restart the container and avatars vanish.

| Provider | Plan | Cost |
|---|---|---|
| **AWS S3** | Standard | $0.023/GB/mo + egress |
| **Cloudflare R2** | $0 egress, $0.015/GB/mo | Cheapest if you serve a lot of images |
| **Google Cloud Storage** | Standard | $0.020/GB/mo |
| **DigitalOcean Spaces** | $5/mo for 250 GB + 1 TB egress | Bundled, predictable |
| **Backblaze B2** | $0.006/GB/mo | Cheapest storage, paid egress |

**Wiring:**
1. `pip install django-storages[s3]` (works for S3, R2, Spaces, B2).
2. In `core/settings.py`:
   ```python
   if os.getenv("AWS_STORAGE_BUCKET_NAME"):
       DEFAULT_FILE_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
       AWS_STORAGE_BUCKET_NAME = os.getenv("AWS_STORAGE_BUCKET_NAME")
       AWS_S3_ENDPOINT_URL = os.getenv("AWS_S3_ENDPOINT_URL")  # for R2/Spaces
       AWS_S3_REGION_NAME = os.getenv("AWS_REGION", "us-east-1")
       AWS_S3_OBJECT_PARAMETERS = {"CacheControl": "max-age=86400"}
       AWS_DEFAULT_ACL = "public-read"
   ```
3. Set the env vars. Old avatars still in the local volume keep working;
   new uploads go to the bucket.

**Recommendation:** **Cloudflare R2** — zero egress fee means CDN bills don't
spiral.

### 2.3 CDN — fast static + media globally

**Why:** without a CDN, every avatar download hits your origin server. With
500 users, that's still fine. With 50 000 across MENA it isn't.

| Provider | Cost | Strengths |
|---|---|---|
| **Cloudflare** | Free tier | Free, generous, simple, includes WAF |
| **AWS CloudFront** | First 1 TB free, then $0.085/GB | Tight S3 integration |
| **Fastly** | $50/mo minimum | Best performance, edge compute |
| **Bunny CDN** | $0.01/GB | Cheapest, simple |

**Wiring:**
1. Already easy if you're on Cloudflare for DNS — flip the orange cloud on the
   `media.your-domain.com` record.
2. Or, on AWS: create a CloudFront distribution with origin = your S3 bucket,
   point `media.your-domain.com` at the distribution, set
   `MEDIA_URL=https://media.your-domain.com/` in `.env`.

**Recommendation:** **Cloudflare** is free and you're already on it for DNS.

### 2.4 Error tracking — Sentry

**Why:** without it, you'll learn about backend crashes from a user complaint
and mobile crashes never. Sentry catches both.

| Provider | Free tier | Paid | Strengths |
|---|---|---|---|
| **Sentry** | 5k errors/mo | $26/mo (50k) | Both Django and Flutter SDKs are first-class |
| **Datadog** | trial | $$$ | Deep APM but expensive |
| **Better Stack** | $0–$25/mo | | Logs + alerts |

**Backend wiring:**
1. `pip install sentry-sdk[django]`.
2. In `core/settings.py`:
   ```python
   if os.getenv("SENTRY_DSN"):
       import sentry_sdk
       from sentry_sdk.integrations.django import DjangoIntegration
       sentry_sdk.init(
           dsn=os.getenv("SENTRY_DSN"),
           integrations=[DjangoIntegration()],
           traces_sample_rate=0.1,
           environment=os.getenv("DJANGO_ENV", "production"),
       )
   ```

**Mobile wiring:**
1. `flutter pub add sentry_flutter`.
2. In `main.dart`:
   ```dart
   await SentryFlutter.init(
     (options) { options.dsn = const String.fromEnvironment('SENTRY_DSN'); },
     appRunner: () => runApp(const MyApp()),
   );
   ```
3. Build with `--dart-define=SENTRY_DSN=...`.

**Recommendation:** **Sentry** — free tier covers a small product easily.

### 2.5 Email delivery — transactional

**Why:** password reset, order receipts, account confirmation. Mongez doesn't
do all of these today, but the moment you add "forgot password" you need an
SMTP/API provider — your hosting provider's port 25 is almost certainly
blocked.

| Provider | Free tier | Paid | Strengths |
|---|---|---|---|
| **AWS SES** | 62k/mo if from EC2 | $0.10 / 1000 | Cheapest at scale |
| **SendGrid** | 100/day free | $19.95/mo | Most popular |
| **Postmark** | 100/mo free | $15/mo (10k) | Best deliverability for transactional |
| **Mailgun** | first 100 free | $35/mo | API-first |
| **Resend** | 100/day, 3k/mo free | $20/mo | Great DX, modern |

**Wiring:**
```python
# core/settings.py
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.getenv("EMAIL_HOST", "smtp.sendgrid.net")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", "587"))
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER", "apikey")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD", "")
EMAIL_USE_TLS = True
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL", "Mongez <noreply@your-domain.com>")
```

**Recommendation:** **Resend** if you're starting fresh — best DX. **SES** if
you're already on AWS and want the cheapest scale.

### 2.6 SMS / OTP — phone verification

**Why:** the user model uses `phone` as the unique identifier. Today nothing
verifies that the phone is real. Critical for fraud prevention.

| Provider | Cost (Egypt) | Strengths |
|---|---|---|
| **Twilio Verify** | ~$0.05/verification | Built-in OTP flow, retry, fraud guard |
| **Vonage** | similar | Wider coverage in Africa |
| **AWS SNS** | $0.07/SMS | Cheapest if already on AWS |
| **MessageBird** | regional | Strong in EMEA |

**Wiring (this is new code, not yet in the project):**
1. Add a `PhoneVerification` model (`phone, code, expires_at, attempts`).
2. New endpoint `POST /api/auth/verify/start/` that calls Twilio Verify or
   sends an SMS via Vonage.
3. New endpoint `POST /api/auth/verify/check/` that verifies the code.
4. Flag `User.phone_verified` set on success — guard sensitive endpoints with
   it via a custom permission.

**Recommendation:** **Twilio Verify** for the simplest path; their SDK handles
all the edge cases (rate-limit, expiry, retries) for you.

### 2.7 Container registry

**Why:** your compute provider needs to pull the Docker image from somewhere.

| Provider | Cost | Strengths |
|---|---|---|
| **GitHub Container Registry (GHCR)** | Free for public repos | Tight GitHub Actions integration |
| **Docker Hub** | $0–$7/mo | Simplest |
| **AWS ECR** | $0.10/GB/mo | Tight ECS/Fargate integration |
| **Google Artifact Registry** | $0.10/GB/mo | Cloud Run native |

**Recommendation:** **GHCR** — already authenticated from GitHub Actions, free,
private repos free up to 500 MB.

### 2.8 CI/CD — GitHub Actions

**Why:** automate test → build → push → deploy on every merge.

Already in the repo at `.github/workflows/`. To strengthen it
(`ENHANCEMENTS.md` §6.10):

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - run: pip install -r requirements.txt
      - run: python manage.py test apps
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.10' }
      - run: cd mobile && flutter pub get && flutter test test/validators_test.dart && flutter analyze
  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:latest
```

**Cost:** GitHub Actions includes 2000 min/month free for private repos.

---

## 3. Nice-to-have services (you'll want them once you have traction)

### 3.1 Centralized logging

**Why:** `docker compose logs` is fine for one container; with 3+ services
you want one search box.

| Provider | Free | Paid | Notes |
|---|---|---|---|
| **Better Stack** | 1 GB/mo free | $25/mo | Simple, modern |
| **Grafana Loki Cloud** | 50 GB/mo free | $$ usage | Pairs with Prometheus |
| **Datadog Logs** | trial | $$$ | Deep but pricey |
| **Papertrail** | 50 MB/day free | $7/mo | Heroku-style tail UI |

**Wiring:** ship Gunicorn's stdout via Vector, Fluent Bit, or the provider's
native agent. Logs are already JSON-friendly because of `--access-logfile -`
in `entrypoint.sh`.

### 3.2 Application performance monitoring (APM)

**Why:** when a checkout is "slow" you want to see which span (DB query,
Paymob call, etc.) is the culprit.

| Provider | Free | Paid |
|---|---|---|
| **Sentry Performance** | bundled with errors free tier | $26/mo |
| **Grafana Tempo** | bundled with Loki cloud | $$ usage |
| **Datadog APM** | trial | $31/host/mo |

**Recommendation:** Sentry's bundled performance — same DSN you already
configured.

### 3.3 Backups (DB + media)

**Why:** every cloud provider's DB has nightly snapshots, but you should also
ship logical dumps off-site so a provider outage doesn't kill you.

```bash
# Cron once a day on any small VM (or GitHub Actions on a schedule)
pg_dump $DATABASE_URL | gzip > backup-$(date +%F).sql.gz
aws s3 cp backup-*.sql.gz s3://mongez-backups/postgres/
```

**Cost:** $0.50/mo storage on most providers for typical app size.

### 3.4 Analytics

**Why:** product decisions need numbers (DAU, funnel, retention).

| Provider | Free | Paid |
|---|---|---|
| **Firebase Analytics** | unlimited free | $0 |
| **PostHog** | 1M events/mo free | $0–$$ |
| **Mixpanel** | 100k MTU free | $25/mo |
| **Amplitude** | 10k MTU free | $$ |

**Recommendation:** **Firebase Analytics** — already adjacent to FCM, free, and
the Flutter SDK (`firebase_analytics`) is one line:
`FirebaseAnalytics.instance.logEvent(name: 'order_placed')`.

### 3.5 Crashlytics for mobile

Bundled with Firebase. Free. Catches native crashes that Sentry alone might
miss on iOS/Android. Add `firebase_crashlytics` to `pubspec.yaml`.

### 3.6 Secrets management

**Why:** so many env vars (`PAYMOB_*`, `FCM_SERVER_KEY`, `SENTRY_DSN`,
`DATABASE_URL`, …) want one source of truth across dev / staging / prod.

| Provider | Free | Paid |
|---|---|---|
| **Doppler** | $0 personal tier | $7/user/mo |
| **AWS Secrets Manager** | — | $0.40/secret/mo |
| **HashiCorp Vault** | self-host free | enterprise |
| **GitHub Secrets** | included | included |

**Recommendation:** **Doppler** for solo/small teams — drop-in CLI replaces
`docker compose --env-file`.

### 3.7 WAF + bot protection

**Why:** the auth throttle protects against brute-force, but a real DDoS will
overwhelm it. Cloudflare's free WAF mitigates the obvious.

**Cost:** $0 on Cloudflare's free tier. Paid Cloudflare ($20/mo) adds rate-
limiting rules and a real WAF.

### 3.8 Status page

**Why:** when something is down, users want to know.

| Provider | Free | Paid |
|---|---|---|
| **Better Stack Status** | free hosted page | $29/mo branded |
| **Statuspage.io** | trial | $29/mo |
| **Self-hosted Cachet** | free | hosting |

**Recommendation:** Better Stack — easiest, includes uptime monitoring.

### 3.9 Maps & geocoding (if you add address lookup)

If you ever upgrade `User.address` from a free-text field to a real
geocoded location, you'll need:

| Provider | Free | Paid |
|---|---|---|
| **Mapbox** | 50k loads/mo | $$ |
| **Google Maps Platform** | $200/mo credit | $$ |
| **OpenStreetMap (Nominatim)** | free if you self-rate-limit | self-host |

---

## 4. Realistic monthly cost — three growth tiers

### Tier 1 — MVP, < 1 000 monthly active users
| Service | Provider | Cost |
|---|---|---|
| Compute | DigitalOcean App Platform basic | $12 |
| PostgreSQL | DigitalOcean Managed (1 GB) | $15 |
| Redis | Upstash free tier | $0 |
| Object storage | Cloudflare R2 (10 GB) | $0.15 |
| DNS + CDN + TLS | Cloudflare free | $0 |
| Email | Resend free | $0 |
| Push | Firebase | $0 |
| Errors | Sentry free | $0 |
| Domain | one .com | $1 |
| **Total** | | **~$28/month** |

### Tier 2 — 10 000 MAU, real revenue
| Service | Provider | Cost |
|---|---|---|
| Compute | Cloud Run / 2× ECS Fargate | $40 |
| PostgreSQL | RDS db.t4g.small + 50 GB | $60 |
| Redis | Upstash pay-per-use | $10 |
| Object storage | R2 (100 GB) | $1.50 |
| CDN | Cloudflare free | $0 |
| Email | SES (50k emails) | $5 |
| Push | Firebase | $0 |
| SMS verify | Twilio (1k/mo) | $50 |
| Errors+APM | Sentry team plan | $26 |
| Logs | Better Stack | $25 |
| Backups | R2 (10 GB) | $0.15 |
| Domain | one .com | $1 |
| **Total** | | **~$220/month** |

### Tier 3 — 100 000+ MAU, multi-region
| Service | Notes | Cost |
|---|---|---|
| Compute | Multi-AZ ECS or GKE | $300+ |
| PostgreSQL | RDS Multi-AZ + read replica | $250+ |
| Redis | ElastiCache cluster | $100+ |
| Object storage + CDN | R2 + CloudFront | $50+ |
| Email | SES (millions) | $80 |
| Push | Firebase | $0 |
| SMS | Twilio (50k) | $2 500 |
| Sentry+APM | Business plan | $80 |
| Logs | Datadog or Better Stack scaled | $200 |
| WAF | Cloudflare Pro | $20 |
| Status page | Better Stack | $29 |
| **Total** | | **~$3 600/month** |

(SMS dominates at scale — pick a regional aggregator if Egypt is your only
market.)

---

## 5. End-to-end deployment recipe

### 5.1 First production deploy (1–2 hours, MVP tier)

1. **Buy a domain** (Cloudflare or Namecheap).
2. **Cloudflare:** add the domain, set NS, enable DNS-only proxy on the
   subdomain you'll use for the API.
3. **DigitalOcean:** create an App from this GitHub repo, dockerfile path
   `./Dockerfile`. Add Managed PostgreSQL ($15) in the same region.
4. **Set env vars in the App's settings:**
   - `DJANGO_SECRET_KEY` — generate fresh
   - `DJANGO_DEBUG=false`
   - `DJANGO_ALLOWED_HOSTS=api.your-domain.com`
   - `CORS_ALLOWED_ORIGINS=https://your-domain.com`
   - `CSRF_TRUSTED_ORIGINS=https://api.your-domain.com,https://your-domain.com`
   - `DATABASE_URL` (DO injects it automatically)
   - `PAYMOB_*` (real credentials)
   - `FCM_SERVER_KEY` (from Firebase console)
   - `SENTRY_DSN` (after creating a Sentry project)
5. **Cloudflare DNS:** point `api.your-domain.com` (CNAME) at DO's app URL.
   Cloudflare auto-issues TLS.
6. **Run migrations remotely:** DO's build runs `python manage.py migrate`
   automatically via `entrypoint.sh`. Verify with `curl
   https://api.your-domain.com/api/health/`.
7. **Create a superuser:** `doctl apps console <app-id> --command "python
   manage.py createsuperuser"`.
8. **Seed categories** via the admin: log in to
   `https://api.your-domain.com/admin/`.
9. **Configure Paymob webhook:** Paymob Dashboard → Notifications → set URL
   to `https://api.your-domain.com/api/payments/webhook/`.
10. **Mobile app:** edit `mobile/lib/core/api/api_constants.dart` to point at
    `https://api.your-domain.com/api/`. Build release APK / IPA.
11. **Submit to TestFlight + Play internal testing** for a closed beta.

### 5.2 Promotion to production
- Beta-test for 2 weeks with friends + family across both stores.
- Add a `staging` environment as a second DO App (or branch deploy).
- Run a security review using GitHub's built-in `code-scanning` (free).
- Switch the Cloudflare proxy on (orange cloud) for DDoS protection.
- Submit to public Play / App Store listings.

---

## 6. Per-service cheat-sheet (which file to edit for each service)

| Service | Files to touch |
|---|---|
| Compute | `Dockerfile` (already prod-ready), provider's web UI |
| PostgreSQL | `core/settings.py` (`DATABASES`), `requirements.txt` (add `dj-database-url`) |
| Redis | `core/settings.py` (`CACHES`), `requirements.txt` (`django-redis`) |
| Object storage | `core/settings.py` (`DEFAULT_FILE_STORAGE`), `requirements.txt` (`django-storages[s3]`) |
| CDN + DNS + TLS | provider UI only — no code changes |
| Email | `core/settings.py` (`EMAIL_*`) |
| FCM (push) | already in `apps/notifications/services.py` — set `FCM_SERVER_KEY` |
| Mobile FCM | `mobile/lib/main.dart` (init), call `registerDeviceToken` after login |
| Paymob | already in `apps/payments/paymob.py` — set `PAYMOB_*` env vars |
| Mobile Paymob iframe | `mobile/lib/features/checkout_feature/screens/checkout_screen.dart` |
| Sentry backend | `core/settings.py`, `requirements.txt` (`sentry-sdk[django]`) |
| Sentry mobile | `mobile/lib/main.dart`, `mobile/pubspec.yaml` |
| SMS verify | new app `apps/auth_otp/` — see §2.6 |
| CI/CD | `.github/workflows/ci.yml` |

---

## 7. One-page summary

**The minimum to ship to end users:** compute + PG + DNS/TLS + FCM + Paymob +
app store accounts. **~$28/month** at MVP scale.

**The next things to add as you grow:** Redis, object storage, email, error
tracking, SMS verification, structured logs, backups, secrets manager.

**Two providers cover most of the surface for a solo team in 2026:**
**Cloudflare** (DNS + CDN + TLS + WAF) and your choice of one of:
**DigitalOcean App Platform** (simplest), **Fly.io** (edge-fast), or
**Google Cloud Run** (scales-to-zero). Add **Firebase** for push +
analytics + crashlytics, **Sentry** for errors, **Resend** for email.

**Everything in this guide that needs code changes already has the wiring
sketched.** No service requires a refactor of the existing app — they all
plug in via env vars or one new dependency.
