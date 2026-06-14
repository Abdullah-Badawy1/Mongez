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
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default=IN_APP)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    # Optional structured payload — useful for "open order #42" deep links from a push tap
    data = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "is_read"]),
            models.Index(fields=["-created_at"]),
        ]

    def __str__(self):
        return f"[{self.type}] {self.title} → {self.user.username}"


class DeviceToken(models.Model):
    """A push-notification token registered by a mobile client (FCM/APNs)."""

    ANDROID = "android"
    IOS = "ios"
    WEB = "web"

    PLATFORM_CHOICES = [
        (ANDROID, "Android"),
        (IOS, "iOS"),
        (WEB, "Web"),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES, default=ANDROID)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_seen_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["user", "is_active"])]

    def __str__(self):
        return f"{self.user.username} ({self.platform})"
