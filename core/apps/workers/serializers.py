from rest_framework import serializers
from apps.users.serializers import UserSerializer
from .models import ServiceCategory, WorkerProfile


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ["id", "name"]


class WorkerProfileSerializer(serializers.ModelSerializer):
  
    user = UserSerializer(read_only=True)
    score = serializers.SerializerMethodField()

    class Meta:
        model  = WorkerProfile
        fields = [
            "id", "user", "profession", "experience_years",
            "average_rating", "completed_jobs", "is_available",
            "score", "created_at",
        ]
        read_only_fields = ["average_rating", "completed_jobs", "created_at"]

    def get_score(self, obj):
        return round(obj.calculate_score(), 2)


class WorkerProfileWriteSerializer(serializers.ModelSerializer):
    
    class Meta:
        model = WorkerProfile
        fields = ["profession", "experience_years", "is_available"]

    def validate(self, attrs):
        # Make sure this worker doesn't already have a profile
        user = self.context["request"].user
        if self.instance is None and hasattr(user, "worker_profile"):
            raise serializers.ValidationError("You already have a worker profile.")
        return attrs

    def create(self, validated_data):
        return WorkerProfile.objects.create(
            user=self.context["request"].user,
            **validated_data,
        )
