from django.contrib.auth.models import AbstractUser
from django.core.validators import RegexValidator
from django.db import models


phone_validator = RegexValidator(
    regex=r"^\+?[0-9 ()-]{7,20}$",
    message="Enter a valid phone number (digits, optional +, spaces, dashes).",
)

eg_phone_validator = RegexValidator(
    regex=r"^(\+?20)?1[0125]\d{8}$",
    message="Enter a valid Egyptian mobile (e.g. +201012345678 or 01012345678).",
)


class Governorate(models.TextChoices):
    CAIRO = "cairo", "Cairo"
    GIZA = "giza", "Giza"
    ALEXANDRIA = "alexandria", "Alexandria"
    BENI_SUEF = "beni_suef", "Beni Suef"
    QALYUBIA = "qalyubia", "Qalyubia"
    SHARQIA = "sharqia", "Sharqia"
    DAKAHLIA = "dakahlia", "Dakahlia"
    MINYA = "minya", "Minya"
    FAYOUM = "fayoum", "Fayoum"
    ASYUT = "asyut", "Asyut"
    SOHAG = "sohag", "Sohag"
    LUXOR = "luxor", "Luxor"
    ASWAN = "aswan", "Aswan"
    PORT_SAID = "port_said", "Port Said"
    SUEZ = "suez", "Suez"
    ISMAILIA = "ismailia", "Ismailia"
    DAMIETTA = "damietta", "Damietta"
    KAFR_SHEIKH = "kafr_sheikh", "Kafr El-Sheikh"
    GHARBIA = "gharbia", "Gharbia"
    MENOFIA = "menofia", "Menofia"
    BEHEIRA = "beheira", "Beheira"
    QENA = "qena", "Qena"
    RED_SEA = "red_sea", "Red Sea"
    NEW_VALLEY = "new_valley", "New Valley"
    MATROUH = "matrouh", "Matrouh"
    NORTH_SINAI = "north_sinai", "North Sinai"
    SOUTH_SINAI = "south_sinai", "South Sinai"


class User(AbstractUser):

    class Role(models.TextChoices):
        CLIENT = "client", "Client"
        WORKER = "worker", "Worker"
        ADMIN = "admin", "Admin"

    phone = models.CharField(
        max_length=20,
        unique=True,
        validators=[phone_validator],
    )
    name_ar = models.CharField(
        max_length=120, blank=True,
        help_text="Arabic display name (الاسم بالعربية).",
    )
    address = models.CharField(max_length=255, blank=True)
    governorate = models.CharField(
        max_length=20,
        choices=Governorate.choices,
        blank=True,
        db_index=True,
    )
    city = models.CharField(max_length=80, blank=True, db_index=True)
    avatar = models.ImageField(upload_to="avatars/", blank=True, null=True)
    role = models.CharField(
        max_length=10,
        choices=Role.choices,
        default=Role.CLIENT,
    )

    REQUIRED_FIELDS = ["phone", "email"]

    def __str__(self):
        return f"{self.username} ({self.role})"

    @property
    def display_name(self):
        return self.name_ar or self.get_full_name() or self.username

    class Meta:
        verbose_name = "user"
        verbose_name_plural = "users"
        ordering = ["-date_joined"]
        indexes = [
            models.Index(fields=["role"]),
            models.Index(fields=["phone"]),
            models.Index(fields=["governorate", "city"]),
        ]