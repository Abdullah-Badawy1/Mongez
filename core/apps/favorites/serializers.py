from rest_framework import serializers
from apps.users.models import User
from apps.workers.serializers import WorkerProfileSerializer
from .models import Favorite


class FavoriteSerializer(serializers.ModelSerializer):
    worker = WorkerProfileSerializer(source="worker.worker_profile", read_only=True)
    worker_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role=User.Role.WORKER),
        source="worker",
        write_only=True,
    )

    class Meta:
        model = Favorite
        fields = ["id", "worker_id", "worker", "created_at"]
        read_only_fields = ["id", "created_at"]
