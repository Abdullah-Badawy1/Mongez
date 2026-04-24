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

Edit `.env` and set a secret key:

```env
DJANGO_SECRET_KEY=replace-this-with-a-long-random-string
DJANGO_DEBUG=false
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ALLOW_ALL_ORIGINS=true
```

Generate a secure key with:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

### 2b. Build and start

```bash
docker compose up --build
```

First run takes ~2 minutes to build the image and download dependencies. Subsequent starts are instant.

You should see:

```
web-1  | Applying users.0001_initial... OK
web-1  | Applying orders.0001_initial... OK
web-1  | ...
web-1  | [INFO] Listening at: http://0.0.0.0:8000
```

### 2c. Verify

```bash
curl http://localhost:8000/api/workers/
```

Expected response:
```json
{"count": 0, "next": null, "previous": null, "results": []}
```

### 2d. Create admin user and seed categories

```bash
docker compose exec web python manage.py createsuperuser
```

Then open **http://localhost:8000/admin/** and log in. Under **Workers → Service Categories**, create a few entries (e.g. `Plumbing`, `Electrical`, `Cleaning`). The mobile app home screen will display these categories.

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
