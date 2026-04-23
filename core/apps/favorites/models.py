from django.db import models
from apps.users.models import User


class Favorite(models.Model):

    client = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="favorites",
    )
    worker = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="favorited_by",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ["client", "worker"]

    def __str__(self):
        return f"{self.client.username} ♥ {self.worker.username}"
