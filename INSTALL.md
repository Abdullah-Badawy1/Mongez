# Installation Guide

Step-by-step instructions for getting Mongez running on a fresh machine.

---

## Requirements

Install these before you begin:

| Tool | Version | Download |
|---|---|---|
| Git | any | https://git-scm.com |
| Docker Desktop | 24+ | https://docs.docker.com/get-docker/ |
| Flutter SDK | 3.10+ | https://docs.flutter.dev/get-started/install |

> **Docker Desktop** includes Docker Compose v2. If you installed Docker Engine on Linux separately, also install the Compose plugin: `sudo apt install docker-compose-plugin`

---

## 1. Clone

```bash
git clone https://github.com/Abdullah-Badawy1/Mongez.git
cd Mongez
```

---

## 2. Backend Setup

### 2a. Create the environment file

```bash
cp .env.example .env
```

`.env.example` is fully commented and groups every variable: Django core,
CORS, JWT, pagination, rate limiting (`THROTTLE_*`), Paymob, and FCM
(`FCM_SERVER_KEY` — leave blank in dev so push delivery is a no-op).

Set a real secret key:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

…and paste the output as `DJANGO_SECRET_KEY` in `.env`.

For Android emulator access, make sure `10.0.2.2` is in
`DJANGO_ALLOWED_HOSTS` (the default already includes it).

### 2b. Build and start

```bash
docker compose up -d --build
```

First run takes ~30 seconds to build and another ~10 seconds to apply
migrations. Subsequent starts are instant.

The image:
- runs as an unprivileged user (`uid 1000`),
- ships a `HEALTHCHECK` that hits `GET /api/health/` every 30 s,
- auto-applies pending migrations on every boot,
- serves static files (admin + DRF browsable API) via WhiteNoise.

Verify health is `healthy` (not just `running`):

```bash
docker compose ps
# STATUS column should read "Up X seconds (healthy)"
```

You should see:

```
web-1  | Applying users.0001_initial... OK
web-1  | Applying orders.0001_initial... OK
web-1  | ...
web-1  | [INFO] Listening at: http://0.0.0.0:8000
```

### 2c. Verify

```bash
curl http://localhost:8000/api/health/
# {"status": "ok"}

curl http://localhost:8000/api/workers/
# {"count":0,"next":null,"previous":null,"results":[]}
```

### 2d. Create admin user and seed categories

```bash
docker compose exec web python manage.py createsuperuser
```

Then open **http://localhost:8000/admin/** and log in. Under **Workers → Service Categories**, create a few entries (e.g. `Plumbing`, `Electrical`, `Cleaning`). The mobile app home screen will display these categories.

### 2e. Run the test suite (optional)

```bash
docker compose exec web python manage.py test apps
# Ran 32 tests in 2.5s — OK
```

---

## 3. Mobile Setup

### 3a. Install Flutter dependencies

```bash
cd mobile
flutter pub get
```

### 3b. Choose your target

**Linux desktop** (fastest for development):
```bash
flutter run -d linux
```

**Web browser:**
```bash
flutter run -d chrome
```

**Android emulator:**

The emulator cannot reach `localhost` on your machine. Before running, update `lib/core/api/api_constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/';
```

Then:
```bash
flutter emulators --launch <emulator_id>
flutter run
```

**Physical Android / iOS device on the same Wi-Fi:**

1. Find your machine's IP address:
   ```bash
   # Linux/macOS
   ip route get 1 | awk '{print $7}'
   ```
2. Update `lib/core/api/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.1.X:8000/api/';
   ```
3. In `docker-compose.yml`, bind the backend to all interfaces:
   ```yaml
   ports:
     - "0.0.0.0:8000:8000"
   ```
4. Restart the backend and run the app.

---

## 4. First Use

1. Open the app — you will see the onboarding screen
2. Tap **Get Started** → choose **Client** or **Worker**
3. Register a new account
4. Log in — the app saves your JWT tokens and takes you to the home screen
5. As a **Client**: browse workers, tap one, tap **Book Now**, and place an order
6. As a **Worker**: go to **Requests** to see incoming orders and accept or reject them

---

## 5. Stopping and Restarting

```bash
# Stop the backend
docker compose down

# Start again (no rebuild needed)
docker compose up

# Start in background
docker compose up -d

# View logs
docker compose logs -f web
```

---

## 6. Resetting Everything

```bash
# Stop containers and delete all data volumes
docker compose down -v

# Restart fresh (runs migrations again)
docker compose up
```

---

## Troubleshooting

**`unable to open database file`**
```bash
docker compose down -v && docker compose up
```

**Mobile shows "connection refused"**
- Check the backend is running: `docker compose ps`
- On Android emulator, use `http://10.0.2.2:8000/api/` not `localhost`
- On a physical device, use your machine's LAN IP

**`flutter pub get` fails**
- Make sure Flutter is on your PATH: `flutter doctor`
- Run `flutter upgrade` if your SDK is out of date

**Admin page returns CSRF error**
Add to `.env`:
```env
CSRF_TRUSTED_ORIGINS=http://localhost:8000
```
Then restart: `docker compose restart web`

**Throttle limits trigger sporadically in development**
Gunicorn runs with 2 workers by default and DRF's default rate-limit cache
is per-process. If you need consistent throttling across workers, set up a
shared cache (Redis):

```env
# .env
CACHES_DEFAULT=django_redis.cache.RedisCache
CACHES_LOCATION=redis://redis:6379/1
```
…and add a `redis:` service to `docker-compose.yml`. For local
development the default in-memory cache is fine.

**Container is `unhealthy`**
```bash
docker compose logs --tail=100 web
docker inspect --format='{{json .State.Health}}' mongez-backend | python3 -m json.tool
```
Healthcheck calls `GET /api/health/`. A 503 typically means a worker
crashed during boot — read the logs.

---

## Docker operations cheat-sheet

| Task | Command |
|---|---|
| Build image | `docker compose build` |
| Start (background) | `docker compose up -d` |
| View logs | `docker compose logs -f web` |
| Run tests | `docker compose exec web python manage.py test apps` |
| Open Django shell | `docker compose exec web python manage.py shell` |
| Make a superuser | `docker compose exec web python manage.py createsuperuser` |
| Apply new migrations | `docker compose exec web python manage.py migrate` (also runs on boot) |
| Restart only | `docker compose restart web` |
| Stop everything | `docker compose down` |
| Wipe data + restart | `docker compose down -v && docker compose up -d` |
