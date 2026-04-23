# Mongez Backend Explanation

This branch is the backend-only branch for Mongez. The mobile project was removed from this branch so backend work can be reviewed, deployed, and tested without Android or Flutter files mixed into the history.

## Branches

| Branch | Purpose |
| --- | --- |
| `main` | Left untouched for production/current baseline |
| `backend` | Organized Django REST backend with the imported `Mongz` backend work |

## Project Layout

```text
.
├── API_links.md
├── explain.md
├── manage.py
├── requirements.txt
└── core
    ├── settings.py
    ├── urls.py
    ├── asgi.py
    ├── wsgi.py
    └── apps
        ├── users
        ├── workers
        ├── orders
        ├── notifications
        ├── payments
        ├── ratings
        └── favorites
```

## Apps

| App | Responsibility |
| --- | --- |
| `users` | Custom user model, roles, registration, login, JWT tokens, profile APIs |
| `workers` | Service categories, worker profile creation, worker listing, filtering, pagination |
| `orders` | Client order creation, worker accept/reject, client cancel/complete workflow |
| `notifications` | In-app notification records and read/unread APIs |
| `payments` | Paymob commission authorization, capture, void, and webhook handling |
| `ratings` | Client ratings for worker/order completion |
| `favorites` | Client favorite worker list |

## Setup

Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run migrations:

```bash
python manage.py migrate
```

Create an admin user:

```bash
python manage.py createsuperuser
```

Run the API locally:

```bash
python manage.py runserver 0.0.0.0:8000
```

For Android emulator calls, use:

```text
http://10.0.2.2:8000/api/
```

## Environment Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `DJANGO_SECRET_KEY` | local development key | Django secret key |
| `DJANGO_DEBUG` | `true` | Enable or disable debug mode |
| `DJANGO_ALLOWED_HOSTS` | `localhost,127.0.0.1,10.0.2.2` | Comma-separated allowed hosts |
| `DJANGO_TIME_ZONE` | `UTC` | Django timezone |
| `SQLITE_PATH` | `db.sqlite3` | SQLite database path |
| `API_PAGE_SIZE` | `20` | Default DRF page size |
| `JWT_ACCESS_MINUTES` | `60` | JWT access token lifetime |
| `JWT_REFRESH_DAYS` | `7` | JWT refresh token lifetime |
| `CORS_ALLOW_ALL_ORIGINS` | same as debug | Allows all CORS origins in local development |
| `CORS_ALLOWED_ORIGINS` | empty | Comma-separated production CORS origins |
| `CSRF_TRUSTED_ORIGINS` | empty | Comma-separated trusted CSRF origins |
| `PAYMOB_API_KEY` | empty | Paymob API key |
| `PAYMOB_INTEGRATION_ID` | `0` | Paymob integration id |
| `PAYMOB_HMAC_SECRET` | empty | Paymob webhook HMAC secret |
| `COMMISSION_AMOUNT` | `20` | Platform commission amount |

Production should set `DJANGO_DEBUG=false`, a real `DJANGO_SECRET_KEY`, real host values, real CORS origins, and Paymob credentials.

## Auth Model

The backend uses a custom `users.User` model with these roles:

```text
client, worker, admin
```

JWT authentication is enabled with Simple JWT. Login and registration both return `access` and `refresh` tokens.

## Order Flow

1. Client creates an order with a service category and optional worker.
2. Backend attempts to authorize the platform commission through Paymob.
3. Matching available workers receive notifications.
4. Worker accepts or rejects the order.
5. On accept, the backend attempts to capture the commission.
6. On reject or cancel, the backend attempts to void the commission hold.
7. Client can mark accepted work as completed.

## Mobile Integration Notes

Use `API_links.md` as the endpoint reference for the Android/mobile client. Public endpoints can be called without a token. Protected endpoints require:

```text
Authorization: Bearer <access_token>
```

When testing on the Android emulator, replace `localhost` with `10.0.2.2`.

## Commit Style

Commits on this branch follow:

```text
type(scope): short description
```

Examples already used on this branch:

```text
feat(auth): add JWT user accounts
feat(orders): add service order workflow
chore(config): wire backend apps for deployment
docs(api): add mobile backend endpoint reference
```

