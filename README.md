# Mongez — Home Services Platform

A full-stack home services app built with **Django REST Framework** (backend) and **Flutter** (mobile). Clients can browse workers, place service orders, and track them in real time. Workers receive and manage incoming requests.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Django 4.2, Django REST Framework, SimpleJWT |
| Mobile | Flutter 3, Dart, BLoC / Cubit, Dio |
| Auth | JWT (access + refresh tokens with auto-refresh) |
| Database | SQLite (default) |
| Container | Docker + Docker Compose |
| CI | GitHub Actions |

---

## Project Structure

```
Mongez/
├── core/                        # Django project
│   ├── settings.py
│   ├── urls.py
│   └── apps/
│       ├── users/               # Auth, profiles
│       ├── workers/             # Worker profiles, categories
│       ├── orders/              # Service orders lifecycle
│       ├── notifications/       # In-app notifications
│       ├── payments/            # Paymob payment integration
│       ├── ratings/             # Worker ratings
│       └── favorites/           # Saved workers
├── mobile/                      # Flutter app
│   └── lib/
│       ├── core/
│       │   ├── api/             # Dio client + JWT interceptor
│       │   ├── models/          # Data models
│       │   ├── services/        # API service layer
│       │   └── bloc/            # BLoC cubits + states
│       └── features/            # Screens by feature
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── .env.example
└── requirements.txt
```

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
# Create a superuser (one-time setup)
docker compose exec web python manage.py createsuperuser

# Visit http://localhost:8000/admin/
# Create ServiceCategory objects (e.g. Plumbing, Electrical, Cleaning)
```

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
| Categories | `GET categories/` |
| Workers | `GET workers/` `GET workers/<id>/` `POST workers/create/` `GET/PATCH workers/me/` |
| Orders | `GET/POST orders/` `POST orders/<id>/accept\|reject\|cancel\|complete/` |
| Notifications | `GET notifications/` `POST notifications/read-all/` |
| Ratings | `POST ratings/` |
| Favorites | `GET/POST favorites/` `DELETE favorites/<id>/` |

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

## Useful Commands

```bash
# Backend
docker compose up -d                         # start in background
docker compose down                          # stop
docker compose logs -f web                   # stream logs
docker compose exec web python manage.py shell

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

For a detailed step-by-step setup guide see [INSTALL.md](INSTALL.md).

---

## License

MIT
