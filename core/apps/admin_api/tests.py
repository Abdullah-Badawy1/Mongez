"""Smoke tests for the admin_api app.

Confirms the dashboard endpoints are wired (routable) and that the
role-based gate works: a non-admin token gets 403, an admin token gets
200 with the expected aggregate shape.
"""
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.users.models import User


class AdminApiAccessControlTests(TestCase):
    """Ensure admin_api endpoints are gated to role == ADMIN."""

    def setUp(self):
        # DRF's throttles and our 5 s admin-dashboard cache both live in
        # Django's default cache, which is LocMem and persists across
        # test methods. Clear so we don't trip the AuthRateThrottle when
        # the suite runs in a different order or alongside users.tests.
        cache.clear()
        self.admin = User.objects.create_user(
            username="admin_test",
            phone="01000000099",
            password="AdminPass123",
            role=User.Role.ADMIN,
        )
        self.client_user = User.objects.create_user(
            username="client_test",
            phone="01000000088",
            password="ClientPass123",
            role=User.Role.CLIENT,
        )
        self.api = APIClient()

    def _auth_as(self, user):
        """Login via the same /api/auth/login/ the dashboard uses."""
        password = "AdminPass123" if user.role == User.Role.ADMIN else "ClientPass123"
        response = self.api.post(
            "/api/auth/login/",
            {"username": user.username, "password": password},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.content)
        token = response.data["tokens"]["access"]
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_dashboard_requires_authentication(self):
        url = reverse("admin-dashboard")
        response = self.api.get(url)
        self.assertEqual(response.status_code, 401)

    def test_dashboard_rejects_non_admin(self):
        self._auth_as(self.client_user)
        response = self.api.get(reverse("admin-dashboard"))
        self.assertEqual(response.status_code, 403)
        self.assertIn("Admin access required", response.data["error"])

    def test_dashboard_allows_admin_and_returns_stats(self):
        self._auth_as(self.admin)
        response = self.api.get(reverse("admin-dashboard"))
        self.assertEqual(response.status_code, 200, response.content)
        body = response.json()
        self.assertIn("stats", body)
        self.assertIn("recent_orders", body)
        for key in (
            "total_users", "total_clients", "total_workers",
            "total_categories", "total_orders", "total_payments",
            "total_revenue", "orders_by_status",
        ):
            self.assertIn(key, body["stats"], f"missing stat key: {key}")
        # Two users created in setUp, both counted.
        self.assertEqual(body["stats"]["total_users"], 2)
        self.assertEqual(body["stats"]["total_clients"], 1)

    def test_user_list_paginates_and_filters_by_role(self):
        self._auth_as(self.admin)
        response = self.api.get(reverse("admin-user-list") + "?role=client")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["count"], 1)
        self.assertEqual(body["results"][0]["role"], "client")

    def test_worker_list_handles_users_without_profile(self):
        """Regression: AdminWorkerListView used to reference
        WorkerProfile.category / .description which don't exist on the
        current model, 500ing on the first worker without a profile."""
        # Add one worker without a WorkerProfile — this is the case that
        # used to trigger the 500.
        from apps.users.models import User
        User.objects.create_user(
            username="bare_worker",
            phone="01000000077",
            password="WorkerPass123",
            role=User.Role.WORKER,
        )
        self._auth_as(self.admin)
        response = self.api.get(reverse("admin-worker-list"))
        self.assertEqual(response.status_code, 200, response.content)
        body = response.json()
        self.assertGreaterEqual(body["count"], 1)
        # Required fields the dashboard reads — would KeyError otherwise.
        row = body["results"][0]
        for key in (
            "id", "user", "profession", "description",
            "experience_years", "average_rating", "completed_jobs",
            "is_available", "score", "has_profile",
        ):
            self.assertIn(key, row, f"missing field: {key}")


class AdminOrderStatusFanoutTests(TestCase):
    """The dashboard's admin status change is the load-bearing mutation
    the mobile sees from the dashboard. Confirm both clients (and the
    assigned worker) get a Notification row so the mobile's
    NotificationCubit picks it up via its 30 s poll, not just the slower
    order-list poll."""

    def setUp(self):
        from apps.workers.models import ServiceCategory
        from apps.orders.models import Order
        from apps.notifications.models import Notification

        cache.clear()
        self.Notification = Notification
        self.admin = User.objects.create_user(
            username="admin_fan",
            phone="01000000299",
            password="AdminPass123",
            role=User.Role.ADMIN,
        )
        self.client_user = User.objects.create_user(
            username="client_fan",
            phone="01000000288",
            password="ClientPass123",
            role=User.Role.CLIENT,
        )
        self.worker = User.objects.create_user(
            username="worker_fan",
            phone="01000000277",
            password="WorkerPass123",
            role=User.Role.WORKER,
        )
        self.category = ServiceCategory.objects.create(name="Test")
        self.order = Order.objects.create(
            client=self.client_user,
            worker=self.worker,
            service_category=self.category,
            description="test fan-out",
            status=Order.PENDING,
        )
        self.api = APIClient()

    def _login_admin(self):
        r = self.api.post(
            "/api/auth/login/",
            {"username": self.admin.username, "password": "AdminPass123"},
            format="json",
        )
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['tokens']['access']}")

    def test_admin_status_change_notifies_client_and_worker(self):
        self._login_admin()
        url = reverse("admin-order-status", kwargs={"pk": self.order.id})

        # PENDING → ACCEPTED
        r = self.api.patch(url, {"status": "ACCEPTED"}, format="json")
        self.assertEqual(r.status_code, 200, r.content)

        client_notes = self.Notification.objects.filter(user=self.client_user)
        worker_notes = self.Notification.objects.filter(user=self.worker)
        self.assertEqual(client_notes.count(), 1, "client should get one notification")
        self.assertEqual(worker_notes.count(), 1, "assigned worker should get one notification")

        # Payload carries enough for the mobile UI to deep-link.
        payload = client_notes.first().data
        self.assertEqual(payload["order_id"], self.order.id)
        self.assertEqual(payload["status"], "ACCEPTED")
        self.assertEqual(payload["changed_by"], "admin")

    def test_admin_no_op_status_change_does_not_spam(self):
        """A PATCH that doesn't change the status shouldn't fan out."""
        self._login_admin()
        url = reverse("admin-order-status", kwargs={"pk": self.order.id})
        # Order is PENDING; PATCH PENDING again.
        r = self.api.patch(url, {"status": "PENDING"}, format="json")
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(self.Notification.objects.count(), 0)
