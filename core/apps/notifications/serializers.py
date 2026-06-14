from rest_framework import serializers
from .models import DeviceToken, Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "title", "message", "type", "is_read", "created_at", "data"]
        read_only_fields = fields


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ["id", "token", "platform", "is_active", "created_at"]
        read_only_fields = ["id", "is_active", "created_at"]
        extra_kwargs = {
            # Disable the unique validator — the view performs an idempotent
            # update_or_create so re-registering a token must not 400.
            "token": {
                "min_length": 16,
                "max_length": 512,
                "validators": [],
            },
        }
