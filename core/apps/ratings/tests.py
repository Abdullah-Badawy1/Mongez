from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.orders.models import Order
from apps.users.models import User
from apps.workers.models import ServiceCategory, WorkerProfile
from .models import Rating


class RatingTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.category = ServiceCategory.objects.create(name="Plumbing")
        cls.client_user = User.objects.create_user(
            username="cliff", phone="+201000000020", password="Sup3r-Secret!",
            role=User.Role.CLIENT,
        )
        cls.worker_user = User.objects.create_user(
            username="will", phone="+201000000021", password="Sup3r-Secret!",
            role=User.Role.WORKER,
        )
        cls.profile = WorkerProfile.objects.create(
            user=cls.worker_user, profession="Plumbing", experience_years=3,
        )

    def _completed_order(self):
        return Order.objects.create(
            client=self.client_user,
            worker=self.worker_user,
            service_category=self.category,
            status=Order.COMPLETED,
        )

    def test_client_can_rate_completed_order(self):
        order = self._completed_order()
        self.client.force_authenticate(user=self.client_user)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 5, "review": "Great work",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.profile.refresh_from_db()
        self.assertEqual(self.profile.average_rating, 5.0)

    def test_cannot_rate_someone_elses_order(self):
        order = self._completed_order()
        other = User.objects.create_user(
            username="other", phone="+201000000022", password="Sup3r-Secret!",
            role=User.Role.CLIENT,
        )
        self.client.force_authenticate(user=other)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 1,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_rate_pending_order(self):
        order = Order.objects.create(
            client=self.client_user, worker=self.worker_user,
            service_category=self.category, status=Order.PENDING,
        )
        self.client.force_authenticate(user=self.client_user)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 4,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_worker_ratings_list_is_public(self):
        order = self._completed_order()
        Rating.objects.create(
            order=order, client=self.client_user, worker=self.worker_user, stars=4,
        )
        response = self.client.get(
            reverse("rating-worker-list", args=[self.worker_user.id]),
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["stars"], 4)
