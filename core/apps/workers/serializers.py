from rest_framework import serializers
from apps.users.serializers import UserSerializer
from .models import ServiceCategory, WorkerProfile


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ["id", "name", "name_ar", "icon", "description", "description_ar"]


class WorkerProfileSerializer(serializers.ModelSerializer):

    user = UserSerializer(read_only=True)
    score = serializers.SerializerMethodField()
    specialties_list = serializers.ListField(child=serializers.CharField(), read_only=True)
    specialties_list_ar = serializers.ListField(child=serializers.CharField(), read_only=True)
    languages_list = serializers.ListField(child=serializers.CharField(), read_only=True)
    service_category = serializers.SerializerMethodField()
    service_category_id = serializers.SerializerMethodField()

    class Meta:
        model = WorkerProfile
        fields = [
            "id", "user",
            "profession", "profession_ar",
            "service_category", "service_category_id",
            "bio", "bio_ar",
            "experience_years",
            "hourly_rate", "minimum_charge", "currency",
            "specialties", "specialties_ar",
            "specialties_list", "specialties_list_ar",
            "languages", "languages_list",
            "response_time_minutes",
            "completion_rate", "accept_rate",
            "working_hours_start", "working_hours_end", "works_friday",
            "latitude", "longitude", "service_radius_km",
            "average_rating", "completed_jobs",
            "is_verified", "is_available", "is_featured",
            "score", "created_at", "updated_at",
        ]
        read_only_fields = [
            "average_rating", "completed_jobs",
            "is_verified", "is_featured",
            "completion_rate", "accept_rate",
            "created_at", "updated_at",
            "service_category", "service_category_id",
        ]

    def _resolve_category(self, obj):
        """Look up ServiceCategory by profession (case-insensitive)."""
        # Cache on the serializer instance for the duration of one request.
        cache = getattr(self, "_cat_cache", None)
        if cache is None:
            cache = {}
            self._cat_cache = cache
        key = (obj.profession or "").lower()
        if key in cache:
            return cache[key]
        cat = ServiceCategory.objects.filter(name__iexact=obj.profession).first()
        cache[key] = cat
        return cat

    def get_service_category(self, obj):
        cat = self._resolve_category(obj)
        if not cat:
            return None
        return {
            "id": cat.id,
            "name": cat.name,
            "name_ar": cat.name_ar,
            "icon": cat.icon,
        }

    def get_service_category_id(self, obj):
        cat = self._resolve_category(obj)
        return cat.id if cat else None

    def get_score(self, obj):
        # `score` may already be annotated by the queryset; avoid recomputing.
        score = getattr(obj, "score", None)
        if score is not None:
            return round(float(score), 2)
        return round(obj.calculate_score(), 2)


class WorkerProfileWriteSerializer(serializers.ModelSerializer):
    """Used by `POST /api/workers/create/` and `PATCH /api/workers/me/`.

    Accepts either of two payload shapes, since the mobile and the
    dashboard happen to send slightly different things:

      * canonical write shape — `profession` (free-text trade label),
        `bio`, …
      * mobile sign-up shape — `category_id` (FK into ServiceCategory)
        plus `description`.

    `category_id` gets translated into `profession` + `profession_ar`
    by looking the ServiceCategory up server-side, which is the single
    source of truth for the list. `description` is just a friendlier
    alias for `bio`.
    """

    # Write-only aliases — they never appear in the response shape
    # (read-side uses WorkerProfileSerializer).
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=ServiceCategory.objects.all(),
        write_only=True,
        required=False,
        help_text="ServiceCategory id; copied into profession + profession_ar.",
    )
    description = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        help_text="Friendly alias for `bio`. Useful so the mobile and the "
                  "admin dashboard can send the same field name.",
    )

    class Meta:
        model = WorkerProfile
        fields = [
            "profession", "profession_ar",
            "category_id",
            "bio", "bio_ar",
            "description",
            "experience_years",
            "hourly_rate", "minimum_charge",
            "specialties", "specialties_ar",
            "languages",
            "response_time_minutes",
            "working_hours_start", "working_hours_end", "works_friday",
            "latitude", "longitude", "service_radius_km",
            "is_available",
        ]
        extra_kwargs = {
            # Required only when the caller didn't send `category_id`.
            # We enforce that in `validate()`.
            "profession": {"required": False, "allow_blank": True},
        }

    def validate_experience_years(self, value):
        if value > 80:
            raise serializers.ValidationError("Experience years looks unrealistic.")
        return value

    def validate_hourly_rate(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError("Hourly rate must be non-negative.")
        return value

    def validate(self, attrs):
        user = self.context["request"].user
        if self.instance is None and hasattr(user, "worker_profile"):
            raise serializers.ValidationError("You already have a worker profile.")

        # Translate the friendly aliases into the underlying model fields.
        category = attrs.pop("category_id", None)
        description = attrs.pop("description", None)
        if category is not None:
            attrs["profession"] = category.name
            if category.name_ar and not attrs.get("profession_ar"):
                attrs["profession_ar"] = category.name_ar
        if description is not None and not attrs.get("bio"):
            attrs["bio"] = description

        # On create, profession must come from somewhere — either the
        # category lookup or the raw `profession` field.
        if self.instance is None and not attrs.get("profession"):
            raise serializers.ValidationError({
                "category_id": "Please pick a service category (or send "
                               "`profession` directly).",
            })
        return attrs

    def create(self, validated_data):
        return WorkerProfile.objects.create(
            user=self.context["request"].user,
            **validated_data,
        )
