# Mongez Backend API Links

Base URL:

```text
http://localhost:8000/api/
```

Android emulator URL:

```text
http://10.0.2.2:8000/api/
```

Authentication header for protected endpoints:

```text
Authorization: Bearer <access_token>
Content-Type: application/json
```

## Auth

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/api/auth/register/` | No | Create a client or worker account |
| POST | `/api/auth/login/` | No | Login and receive JWT tokens |
| POST | `/api/auth/token/refresh/` | No | Create a new access token from a refresh token |

Register body:

```json
{
  "username": "ahmed",
  "phone": "01012345678",
  "address": "Cairo, Egypt",
  "password": "password123",
  "role": "client"
}
```

`role` can be `client` or `worker`.

Login body:

```json
{
  "username": "ahmed",
  "password": "password123"
}
```

Refresh body:

```json
{
  "refresh": "<refresh_token>"
}
```

## Profile

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/users/me/` | Yes | Get current user profile |
| PATCH | `/api/users/me/` | Yes | Update current user profile |

Patch body example:

```json
{
  "username": "ahmed_new",
  "phone": "01099999999",
  "address": "Alexandria, Egypt"
}
```

## Categories

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/categories/` | No | List service categories |
| POST | `/api/categories/create/` | Yes, admin | Create a service category |

Create body:

```json
{
  "name": "Plumbing"
}
```

## Workers

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/workers/` | No | List available workers |
| POST | `/api/workers/create/` | Yes, worker | Create worker profile |
| GET | `/api/workers/me/` | Yes, worker | Get my worker profile |
| PATCH | `/api/workers/me/` | Yes, worker | Update my worker profile |
| GET | `/api/workers/<id>/` | No | Get worker profile details |

Worker list query parameters:

| Parameter | Example | Purpose |
| --- | --- | --- |
| `category` | `/api/workers/?category=1` | Filter by service category id |
| `search` | `/api/workers/?search=plumb` | Filter by profession text |
| `page` | `/api/workers/?page=2` | Pagination page |
| `page_size` | `/api/workers/?page_size=5` | Results per page, max 50 |

Create or update worker profile body:

```json
{
  "profession": "Plumbing",
  "experience_years": 5,
  "is_available": true
}
```

## Orders

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/orders/` | Yes | List my orders |
| POST | `/api/orders/` | Yes, client | Create order and authorize commission |
| GET | `/api/orders/<id>/` | Yes | Get order details |
| POST | `/api/orders/<id>/accept/` | Yes, worker | Accept pending order |
| POST | `/api/orders/<id>/reject/` | Yes, worker | Reject pending order |
| POST | `/api/orders/<id>/cancel/` | Yes, client | Cancel pending order |
| POST | `/api/orders/<id>/complete/` | Yes, worker | Mark accepted order complete |

Create order body:

```json
{
  "service_category": 1,
  "worker_id": 2
}
```

`worker_id` is optional. The create response can include `payment_key` for Paymob payment UI.

Order statuses:

```text
PENDING, ACCEPTED, REJECTED, CANCELLED, COMPLETED
```

## Notifications

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/notifications/` | Yes | List my notifications |
| POST | `/api/notifications/read-all/` | Yes | Mark all notifications as read |
| POST | `/api/notifications/<id>/read/` | Yes | Mark one notification as read |

## Payments

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/api/payments/webhook/?hmac=<paymob_hmac>` | Paymob callback | Receive Paymob transaction updates |

The mobile app normally does not call this endpoint directly. Configure it in the Paymob dashboard as the transaction processed callback URL.

## Ratings

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/api/ratings/` | Yes, client | Rate a completed worker/order |

Rating body:

```json
{
  "order": 10,
  "stars": 5,
  "review": "Great work"
}
```

## Favorites

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/favorites/` | Yes, client | List favorite workers |
| POST | `/api/favorites/` | Yes, client | Add worker to favorites |
| DELETE | `/api/favorites/<id>/` | Yes, client | Remove favorite item |

Add favorite body:

```json
{
  "worker_id": 2
}
```
