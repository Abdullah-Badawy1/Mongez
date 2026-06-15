from unittest.mock import patch

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User
from apps.workers.models import ServiceCategory, WorkerProfile
from .models import Order


class OrderLifecycleTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.category = ServiceCategory.objects.create(name="Plumbing")
        cls.client_user = User.objects.create_user(
            username="cliff", phone="+201000000010", password="Sup3r-Secret!",
            role=User.Role.CLIENT,
        )
        cls.worker_user = User.objects.create_user(
            username="will", phone="+201000000011", password="Sup3r-Secret!",
            role=User.Role.WORKER,
        )
        WorkerProfile.objects.create(
            user=cls.worker_user, profession="Plumbing", experience_years=3,
        )

    def _create_order(self):
        with patch("apps.orders.views.authorize_commission", return_value="dummy_key"):
            self.client.force_authenticate(user=self.client_user)
            return self.client.post(reverse("order-list-create"), {
                "service_category": self.category.id,
                "worker_id": self.worker_user.id,
            }, format="json")

    def test_client_can_create_pending_order(self):
        response = self._create_order()
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.assertEqual(response.data["status"], Order.PENDING)

    def test_worker_can_accept_order(self):
        create_resp = self._create_order()
        order_id = create_resp.data["id"]

        self.client.force_authenticate(user=self.worker_user)
        with patch("apps.orders.views.paymob.capture_commission", return_value={}):
            accept_resp = self.client.post(reverse("order-accept", args=[order_id]))
        self.assertEqual(accept_resp.status_code, status.HTTP_200_OK, accept_resp.data)
        self.assertEqual(accept_resp.data["status"], Order.ACCEPTED)

    def test_two_step_completion_requires_client_confirmation(self):
        create_resp = self._create_order()
        order_id = create_resp.data["id"]

        # Worker accepts then marks finished — should land in WAITING_CONFIRMATION,
        # NOT bump completed_jobs yet.
        self.client.force_authenticate(user=self.worker_user)
        with patch("apps.orders.views.paymob.capture_commission", return_value={}):
            self.client.post(reverse("order-accept", args=[order_id]))
        mark_resp = self.client.post(reverse("order-complete", args=[order_id]))
        self.assertEqual(mark_resp.status_code, status.HTTP_200_OK, mark_resp.data)
        self.assertEqual(mark_resp.data["status"], Order.WAITING_CONFIRMATION)
        self.worker_user.worker_profile.refresh_from_db()
        self.assertEqual(self.worker_user.worker_profile.completed_jobs, 0)

        # Client confirms — order closes, counter bumps.
        self.client.force_authenticate(user=self.client_user)
        confirm_resp = self.client.post(reverse("order-confirm-completion", args=[order_id]))
        self.assertEqual(confirm_resp.status_code, status.HTTP_200_OK, confirm_resp.data)
        self.assertEqual(confirm_resp.data["status"], Order.COMPLETED)
        self.worker_user.worker_profile.refresh_from_db()
        self.assertEqual(self.worker_user.worker_profile.completed_jobs, 1)

    def test_worker_cannot_order_in_own_profession(self):
        self.client.force_authenticate(user=self.worker_user)
        with patch("apps.orders.views.authorize_commission", return_value="dummy_key"):
            resp = self.client.post(reverse("order-list-create"), {
                "service_category": self.category.id,
            }, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("service_category", resp.data)

    def test_worker_can_order_other_category(self):
        other = ServiceCategory.objects.create(name="Electrical")
        electrician = User.objects.create_user(
            username="ed", phone="+201000000012", password="Sup3r-Secret!",
            role=User.Role.WORKER,
        )
        WorkerProfile.objects.create(
            user=electrician, profession="Electrical", experience_years=2,
        )
        self.client.force_authenticate(user=self.worker_user)
        with patch("apps.orders.views.authorize_commission", return_value="dummy_key"):
            resp = self.client.post(reverse("order-list-create"), {
                "service_category": other.id,
                "worker_id": electrician.id,
            }, format="json")
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED, resp.data)
        self.assertEqual(resp.data["status"], Order.PENDING)

    def test_client_cannot_accept_order(self):
        create_resp = self._create_order()
        order_id = create_resp.data["id"]

        self.client.force_authenticate(user=self.client_user)
        accept_resp = self.client.post(reverse("order-accept", args=[order_id]))
        self.assertEqual(accept_resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_accept_already_accepted_order(self):
        create_resp = self._create_order()
        order_id = create_resp.data["id"]

        self.client.force_authenticate(user=self.worker_user)
        with patch("apps.orders.views.paymob.capture_commission", return_value={}):
            self.client.post(reverse("order-accept", args=[order_id]))
            second = self.client.post(reverse("order-accept", args=[order_id]))
        self.assertEqual(second.status_code, status.HTTP_400_BAD_REQUEST)

    def test_client_can_cancel_pending_order(self):
        create_resp = self._create_order()
        order_id = create_resp.data["id"]

        with patch("apps.orders.views.paymob.void_commission", return_value={}):
            cancel_resp = self.client.post(reverse("order-cancel", args=[order_id]))
        self.assertEqual(cancel_resp.status_code, status.HTTP_200_OK, cancel_resp.data)
        self.assertEqual(cancel_resp.data["status"], Order.CANCELLED)

    def test_filter_orders_by_status(self):
        self._create_order()
        response = self.client.get(reverse("order-list-create"), {"status": "PENDING"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        statuses = {o["status"] for o in response.data}
        self.assertEqual(statuses, {Order.PENDING})
