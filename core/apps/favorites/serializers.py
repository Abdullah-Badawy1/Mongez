from rest_framework import serializers
from apps.users.models import User
from apps.users.serializers import UserSerializer
from .models import Favorite


class FavoriteSerializer(serializers.ModelSerializer):
    worker_info = UserSerializer(source="worker", read_only=True)
    worker_id = serializers.PrimaryKeyRelatedField(
        queryset = User.objects.filter(role=User.Role.WORKER),
        source = "worker",
        write_only = True,
    )

    class Meta:
        model = Favorite
        fields = ["id", "worker_id", "worker_info", "created_at"]
        read_only_fields = ["id", "created_at"]
