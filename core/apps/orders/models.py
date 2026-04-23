from django.db import models
from apps.users.models import User
from apps.workers.models import ServiceCategory


class Order(models.Model):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"

    STATUS_CHOICES = [
        (PENDING, "Pending"),
        (ACCEPTED, "Accepted"),
        (REJECTED, "Rejected"),
        (CANCELLED, "Cancelled"),
        (COMPLETED, "Completed"),
    ]

    client = models.ForeignKey(
        User,
        on_delete = models.CASCADE,
        related_name = "my_orders",
    )
    worker = models.ForeignKey(
        User,
        on_delete = models.SET_NULL,
        null = True,
        blank = True,
        related_name = "assigned_orders",
    )
        
    service_category = models.ForeignKey(
        ServiceCategory,
        on_delete = models.PROTECT,
    )
    commission = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(
        max_length = 10,
        choices = STATUS_CHOICES,
        default = PENDING,
    )

    created_at = models.DateTimeField(auto_now_add=True)
    accepted_at  = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Order #{self.id} [{self.status}] — {self.client.username}"
