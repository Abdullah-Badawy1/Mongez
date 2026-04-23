from django.db import models
from apps.users.models import User
from apps.orders.models import Order


class Rating(models.Model):

    order = models.OneToOneField(
        Order,
        on_delete= models.CASCADE,
        related_name= "rating",
    )
    client = models.ForeignKey(
        User,
        on_delete= models.CASCADE,
        related_name= "given_ratings",
    )
    worker = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="received_ratings",
    )
    stars = models.PositiveSmallIntegerField()  # 1 to 5
    review = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.stars}★  Order #{self.order_id}"
