from django.db import models
from apps.users.models import User


class Notification(models.Model):

    PUSH = "push"
    IN_APP = "in_app"
    EMAIL = "email"

    TYPE_CHOICES = [
        (PUSH,   "Push"),
        (IN_APP, "In-App"),
        (EMAIL,  "Email"),
    ]

    user = models.ForeignKey(
        User,
        on_delete = models.CASCADE,
        related_name = "notifications",
    )
    title  = models.CharField(max_length=255)
    message = models.TextField()
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default=IN_APP)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"[{self.type}] {self.title} → {self.user.username}"
