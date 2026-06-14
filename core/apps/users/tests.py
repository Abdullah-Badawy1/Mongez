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
            "governorate": "cairo",
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
            "governorate": "giza",
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


class RegisterFormFixesTests(APITestCase):
    """Cover the two issues users hit on the mobile sign-up form:

    1. Sending only the truly required fields used to 400 because
       ModelSerializer infers required=True for model CharFields even
       when blank=True. RegisterSerializer now marks name_ar / address /
       governorate / city as required=False explicitly.
    2. Typing a username with a space used to surface the opaque
       Django-default "letters, numbers, and @/./+/-/_" message. The
       serializer now catches the space case first with a hint that the
       display name lives in a separate field.
    """

    def test_register_with_only_required_fields(self):
        # The minimal payload now also includes `governorate` — every
        # Egyptian account must be tagged with a home governorate so
        # the dashboard can filter by it.
        url = reverse("register")
        response = self.client.post(url, {
            "username": "minimal_worker",
            "phone": "+201112223344",
            "governorate": "cairo",
            "password": "Sup3r-Secret!",
            "role": "worker",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.assertEqual(response.data["user"]["username"], "minimal_worker")
        self.assertEqual(response.data["user"]["role"], "worker")
        self.assertEqual(response.data["user"]["governorate"], "cairo")

    def test_register_with_name_ar_and_separate_username(self):
        # Real mobile flow — display name with spaces in name_ar, login
        # handle in username with no spaces, governorate + city replacing
        # the legacy free-text address.
        url = reverse("register")
        response = self.client.post(url, {
            "username": "ahmed_hassan",
            "name_ar": "أحمد حسن",
            "phone": "+201112223355",
            "governorate": "cairo",
            "city": "Nasr City",
            "password": "Sup3r-Secret!",
            "role": "worker",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        body = response.data
        self.assertEqual(body["user"]["username"], "ahmed_hassan")
        self.assertEqual(body["user"]["name_ar"], "أحمد حسن")
        self.assertEqual(body["user"]["display_name"], "أحمد حسن")
        self.assertEqual(body["user"]["governorate"], "cairo")
        self.assertEqual(body["user"]["city"], "Nasr City")

    def test_register_rejects_unknown_governorate(self):
        url = reverse("register")
        response = self.client.post(url, {
            "username": "wrong_gov",
            "phone": "+201112223388",
            "governorate": "atlantis",       # not in the 27-code enum
            "password": "Sup3r-Secret!",
            "role": "client",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("governorate", response.data)

    def test_register_username_with_space_returns_clear_message(self):
        url = reverse("register")
        response = self.client.post(url, {
            "username": "Ahmed Ali",          # the failure case the user reported
            "name_ar": "Ahmed Ali",
            "phone": "+201112223366",
            "governorate": "cairo",
            "password": "Sup3r-Secret!",
            "role": "worker",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("username", response.data)
        # Custom-friendly message, not the opaque Django default.
        msg = response.data["username"][0]
        self.assertIn("spaces", msg.lower())


class GovernoratesEndpointTests(APITestCase):
    """Endpoint that the mobile + dashboard hydrate their governorate
    dropdowns from."""

    def test_governorates_endpoint_returns_27_entries_with_arabic_names(self):
        response = self.client.get(reverse("governorates"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.data
        self.assertEqual(len(body), 27)
        cairo = next((g for g in body if g["code"] == "cairo"), None)
        self.assertIsNotNone(cairo)
        self.assertEqual(cairo["name_en"], "Cairo")
        self.assertEqual(cairo["name_ar"], "القاهرة")
        # Each row has all three fields.
        for g in body:
            self.assertIn("code", g)
            self.assertIn("name_en", g)
            self.assertIn("name_ar", g)
