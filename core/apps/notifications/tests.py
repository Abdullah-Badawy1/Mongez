from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User
from .models import DeviceToken, Notification
from .services import notify


class NotificationTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="bob", phone="+201000000040", password="Sup3r-Secret!",
            role=User.Role.CLIENT,
        )
        self.client.force_authenticate(user=self.user)

    def test_notify_persists_row(self):
        notif = notify(user=self.user, title="Hi", message="There")
        self.assertEqual(Notification.objects.count(), 1)
        self.assertEqual(notif.title, "Hi")

    def test_unread_count_endpoint(self):
        notify(user=self.user, title="A", message="B")
        notify(user=self.user, title="C", message="D")
        response = self.client.get(reverse("notification-unread-count"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["unread"], 2)

    def test_mark_all_read(self):
        notify(user=self.user, title="A", message="B")
        notify(user=self.user, title="C", message="D")
        response = self.client.post(reverse("notification-read-all"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            Notification.objects.filter(user=self.user, is_read=False).count(), 0,
        )

    def test_register_device_token_idempotent(self):
        url = reverse("notification-device-register")
        first = self.client.post(url, {"token": "abcd1234abcd1234", "platform": "android"}, format="json")
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)
        second = self.client.post(url, {"token": "abcd1234abcd1234", "platform": "android"}, format="json")
        self.assertEqual(second.status_code, status.HTTP_201_CREATED)
        self.assertEqual(DeviceToken.objects.count(), 1)
