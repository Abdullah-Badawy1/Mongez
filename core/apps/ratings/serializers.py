from django.db.models import Avg
from rest_framework import serializers
from apps.orders.models import Order
from .models import Rating


class RatingSerializer(serializers.ModelSerializer):
    order = serializers.PrimaryKeyRelatedField(queryset=Order.objects.all())

    class Meta:
        model = Rating
        fields = ["id", "order", "stars", "review", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_stars(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("Stars must be between 1 and 5.")
        return value

    def validate_order(self, order):
        user = self.context["request"].user

        if order.client != user:
            raise serializers.ValidationError("You can only rate your own orders.")

        if order.status != Order.COMPLETED:
            raise serializers.ValidationError("The order must be completed before rating.")

        if hasattr(order, "rating"):
            raise serializers.ValidationError("You already rated this order.")

        return order

    def create(self, validated_data):
        order = validated_data["order"]
        client = self.context["request"].user
        worker = order.worker

        rating = Rating.objects.create(
            order=order,
            client=client,
            worker=worker,
            stars=validated_data["stars"],
            review=validated_data.get("review", ""),
        )

        # Recalculate and update the worker's average rating immediately
        new_avg = (
            Rating.objects
            .filter(worker=worker)
            .aggregate(avg=Avg("stars"))["avg"]
        ) or 0.0

        profile = worker.worker_profile
        profile.average_rating = round(new_avg, 2)
        profile.save()

        return rating
