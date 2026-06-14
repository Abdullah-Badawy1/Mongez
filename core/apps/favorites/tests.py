from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User
from apps.workers.models import WorkerProfile
from .models import Favorite


class FavoriteTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.client_user = User.objects.create_user(
            username="cliff", phone="+201000000030", password="Sup3r-Secret!",
            role=User.Role.CLIENT,
        )
        cls.worker_user = User.objects.create_user(
            username="will", phone="+201000000031", password="Sup3r-Secret!",
            role=User.Role.WORKER,
        )
        WorkerProfile.objects.create(
            user=cls.worker_user, profession="Plumbing", experience_years=3,
        )

    def test_client_can_add_favorite(self):
        self.client.force_authenticate(user=self.client_user)
        response = self.client.post(reverse("favorite-list-create"), {
            "worker_id": self.worker_user.id,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.assertTrue(Favorite.objects.filter(client=self.client_user).exists())

    def test_cannot_add_same_worker_twice(self):
        self.client.force_authenticate(user=self.client_user)
        self.client.post(reverse("favorite-list-create"), {
            "worker_id": self.worker_user.id,
        }, format="json")
        again = self.client.post(reverse("favorite-list-create"), {
            "worker_id": self.worker_user.id,
        }, format="json")
        self.assertEqual(again.status_code, status.HTTP_400_BAD_REQUEST)

    def test_remove_by_worker_id(self):
        Favorite.objects.create(client=self.client_user, worker=self.worker_user)
        self.client.force_authenticate(user=self.client_user)
        response = self.client.delete(
            reverse("favorite-by-worker-delete", args=[self.worker_user.id])
        )
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Favorite.objects.exists())

    def test_workers_cannot_use_favorites(self):
        self.client.force_authenticate(user=self.worker_user)
        response = self.client.get(reverse("favorite-list-create"))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
