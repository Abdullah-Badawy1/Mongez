from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN  = 'admin',  'Admin'
        WORKER = 'worker', 'Worker'
        CLIENT = 'client', 'Client'

    phone   = models.CharField(max_length=20, unique=True)
    address = models.TextField(blank=True, null=True)
    role    = models.CharField(max_length=10, choices=Role.choices, default=Role.CLIENT)

    email = models.EmailField(unique=True)

    REQUIRED_FIELDS = ['phone', 'email']  
    USERNAME_FIELD  = 'username'         

    def __str__(self):
        return f"{self.username} ({self.role})"