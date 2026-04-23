from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):

    class Role(models.TextChoices):
        CLIENT = "client", "Client"
        WORKER = "worker", "Worker"
        ADMIN = "admin",  "Admin"

    phone = models.CharField(max_length=20, unique=True)
    address = models.CharField(max_length=255, blank=True)
    role = models.CharField(
        max_length=10,
        choices=Role.choices,
        default=Role.CLIENT,
    )

    REQUIRED_FIELDS = ["phone", "email"]

    def __str__(self):
        return f"{self.username} ({self.role})"
        
    class Meta:
        verbose_name = "user"
        verbose_name_plural = "users"
        ordering = ["-date_joined"]