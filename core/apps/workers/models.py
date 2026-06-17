from django.db import models
from apps.users.models import User


class ServiceCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    name_ar = models.CharField(max_length=100, blank=True, help_text="Arabic name (الاسم بالعربية)")
    icon = models.CharField(max_length=64, blank=True, help_text="Optional icon name/key for the mobile app")
    image = models.ImageField(upload_to="categories/", blank=True, null=True)
    description = models.CharField(max_length=255, blank=True)
    description_ar = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class WorkerProfile(models.Model):

    CURRENCY_EGP = "EGP"

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="worker_profile",
    )
    profession = models.CharField(max_length=200)
    profession_ar = models.CharField(max_length=200, blank=True, help_text="Profession in Arabic (المهنة)")
    bio = models.TextField(blank=True, max_length=1000)
    bio_ar = models.TextField(blank=True, max_length=1000, help_text="Bio in Arabic (نبذة)")

    experience_years = models.PositiveIntegerField(default=0)
    hourly_rate = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True,
        help_text="Indicative hourly rate in EGP.",
    )
    minimum_charge = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True,
        help_text="Minimum call-out fee in EGP.",
    )
    currency = models.CharField(max_length=3, default=CURRENCY_EGP)

    # Talents / specialties: stored as a comma-separated string for portability with SQLite.
    specialties = models.CharField(
        max_length=400, blank=True,
        help_text="Comma-separated specialties (e.g. 'AC install,fridge repair').",
    )
    specialties_ar = models.CharField(max_length=400, blank=True)
    languages = models.CharField(
        max_length=80, blank=True,
        help_text="Comma-separated language codes (ar,en,fr,...)",
        default="ar",
    )

    # SLA / performance
    response_time_minutes = models.PositiveIntegerField(
        default=30,
        help_text="Typical response time to a new order, in minutes.",
    )
    completion_rate = models.FloatField(default=0.0, help_text="Percentage 0-100.")
    accept_rate = models.FloatField(default=0.0, help_text="Percentage 0-100.")

    # Working hours (24h, e.g. 9, 22)
    working_hours_start = models.PositiveSmallIntegerField(default=8)
    working_hours_end = models.PositiveSmallIntegerField(default=22)
    works_friday = models.BooleanField(default=False)

    # Geo — optional, used for future map / nearby ranking.
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
    )
    service_radius_km = models.PositiveSmallIntegerField(
        default=10, help_text="How far the worker is willing to travel."
    )

    average_rating = models.FloatField(default=0.0)
    completed_jobs = models.PositiveIntegerField(default=0)
    is_verified = models.BooleanField(default=False, help_text="ID-verified worker (شغل موثّق).")
    is_available = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False, help_text="Pinned to the top of listings.")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["is_available", "-average_rating"]),
            models.Index(fields=["profession"]),
            models.Index(fields=["is_verified"]),
            models.Index(fields=["is_featured", "-average_rating"]),
            models.Index(fields=["latitude", "longitude"]),
        ]

    def __str__(self):
        return f"{self.user.username} — {self.profession}"

    @property
    def specialties_list(self):
        return [s.strip() for s in self.specialties.split(",") if s.strip()]

    @property
    def specialties_list_ar(self):
        src = self.specialties_ar or ""
        return [s.strip() for s in src.split(",") if s.strip()]

    @property
    def languages_list(self):
        return [s.strip() for s in self.languages.split(",") if s.strip()]

    def calculate_score(self):
        verified_bonus = 0.5 if self.is_verified else 0
        featured_bonus = 1.0 if self.is_featured else 0
        return (
            (self.average_rating * 0.6)
            + (self.completed_jobs * 0.4)
            + verified_bonus
            + featured_bonus
        )
