from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User
from .models import ServiceCategory, WorkerProfile


class WorkerListTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.plumbing = ServiceCategory.objects.create(name="Plumbing")
        cls.electrical = ServiceCategory.objects.create(name="Electrical")

        cls.alice = User.objects.create_user(
            username="alice", phone="+201111111101", password="Sup3r-Secret!",
            role=User.Role.WORKER,
        )
        cls.bob = User.objects.create_user(
            username="bob", phone="+201111111102", password="Sup3r-Secret!",
            role=User.Role.WORKER,
        )
        WorkerProfile.objects.create(
            user=cls.alice, profession="Plumbing", experience_years=5,
            average_rating=4.6, completed_jobs=20,
        )
        WorkerProfile.objects.create(
            user=cls.bob, profession="Electrical", experience_years=2,
            average_rating=3.0, completed_jobs=4,
        )

    def test_workers_list_default_sorted_by_score(self):
        response = self.client.get(reverse("worker-list"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        usernames = [w["user"]["username"] for w in response.data["results"]]
        self.assertEqual(usernames[0], "alice")  # higher score wins

    def test_filter_by_category(self):
        response = self.client.get(
            reverse("worker-list"), {"category": self.plumbing.id},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        usernames = [w["user"]["username"] for w in response.data["results"]]
        self.assertEqual(usernames, ["alice"])

    def test_min_rating_filter(self):
        response = self.client.get(reverse("worker-list"), {"min_rating": "4.0"})
        usernames = [w["user"]["username"] for w in response.data["results"]]
        self.assertEqual(usernames, ["alice"])

    def test_search_matches_profession_or_username(self):
        response = self.client.get(reverse("worker-list"), {"search": "bob"})
        usernames = [w["user"]["username"] for w in response.data["results"]]
        self.assertIn("bob", usernames)

    def test_stats_endpoint(self):
        profile = self.alice.worker_profile
        response = self.client.get(
            reverse("worker-stats", args=[profile.id]),
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["worker_id"], profile.id)
        self.assertIn("orders", response.data)
        self.assertIn("ratings", response.data)
        self.assertEqual(set(response.data["ratings"]["distribution"].keys()),
                         {"1", "2", "3", "4", "5"})


class WorkerProfileWriteTests(APITestCase):
    def test_only_workers_can_create_profile(self):
        client_user = User.objects.create_user(
            username="cliff", phone="+201000000005", password="Sup3r-Secret!",
            role=User.Role.CLIENT,
        )
        self.client.force_authenticate(user=client_user)
        response = self.client.post(reverse("worker-create"), {
            "profession": "Plumbing", "experience_years": 1,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_worker_can_create_then_update_profile(self):
        worker = User.objects.create_user(
            username="will", phone="+201000000006", password="Sup3r-Secret!",
            role=User.Role.WORKER,
        )
        self.client.force_authenticate(user=worker)
        create_resp = self.client.post(reverse("worker-create"), {
            "profession": "Carpentry", "experience_years": 4,
        }, format="json")
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED, create_resp.data)

        # Trying again should fail
        again = self.client.post(reverse("worker-create"), {
            "profession": "Carpentry", "experience_years": 4,
        }, format="json")
        self.assertEqual(again.status_code, status.HTTP_400_BAD_REQUEST)

        patch_resp = self.client.patch(reverse("worker-me"), {
            "experience_years": 6, "bio": "Skilled carpenter",
        }, format="json")
        self.assertEqual(patch_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_resp.data["experience_years"], 6)
