from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import User


class AuthFlowTests(APITestCase):
    def test_register_creates_user_and_returns_tokens(self):
        url = reverse("register")
        payload = {
            "username": "alice",
            "phone": "+201111111111",
            "address": "Cairo",
            "password": "Sup3r-Secret!",
            "role": "client",
        }
        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.assertIn("access", response.data["tokens"])
        self.assertEqual(response.data["user"]["username"], "alice")
        self.assertTrue(User.objects.filter(username="alice").exists())

    def test_cannot_register_as_admin(self):
        url = reverse("register")
        payload = {
            "username": "trickster",
            "phone": "+201112223333",
            "password": "Sup3r-Secret!",
            "role": "admin",
        }
        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_duplicate_phone_rejected(self):
        User.objects.create_user(
            username="bob", phone="+201234567890", password="Sup3r-Secret!",
        )
        url = reverse("register")
        response = self.client.post(url, {
            "username": "bob2",
            "phone": "+201234567890",
            "password": "Sup3r-Secret!",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_returns_tokens(self):
        User.objects.create_user(
            username="carol", phone="+201000000001", password="Sup3r-Secret!",
        )
        response = self.client.post(reverse("login"), {
            "username": "carol", "password": "Sup3r-Secret!",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data["tokens"])

    def test_login_with_bad_password_fails(self):
        User.objects.create_user(
            username="dave", phone="+201000000002", password="Sup3r-Secret!",
        )
        response = self.client.post(reverse("login"), {
            "username": "dave", "password": "wrong",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_password_change_rotates_tokens(self):
        user = User.objects.create_user(
            username="eve", phone="+201000000003", password="Sup3r-Secret!",
        )
        self.client.force_authenticate(user=user)
        response = self.client.put(reverse("password-change"), {
            "current_password": "Sup3r-Secret!",
            "new_password": "Even-More-Secret!23",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        user.refresh_from_db()
        self.assertTrue(user.check_password("Even-More-Secret!23"))
