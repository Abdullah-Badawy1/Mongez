from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    """Read-only projection of a user — used inside other resources."""

    avatar_url = serializers.SerializerMethodField()
    display_name = serializers.CharField(read_only=True)
    governorate_label = serializers.CharField(source="get_governorate_display", read_only=True)

    class Meta:
        model = User
        fields = [
            "id", "username", "name_ar", "display_name",
            "email", "phone", "address",
            "governorate", "governorate_label", "city",
            "role", "avatar_url", "date_joined",
        ]
        read_only_fields = fields

    def get_avatar_url(self, obj):
        if not obj.avatar:
            return None
        request = self.context.get("request") if hasattr(self, "context") else None
        url = obj.avatar.url
        return request.build_absolute_uri(url) if request else url


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    email = serializers.EmailField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            "username", "name_ar", "email", "phone", "address",
            "governorate", "city", "password", "role",
        ]

    def validate_role(self, value):
        if value == User.Role.ADMIN:
            raise serializers.ValidationError("You cannot register as admin.")
        return value

    def validate_phone(self, value):
        if User.objects.filter(phone=value).exists():
            raise serializers.ValidationError("Phone number is already registered.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("Username is taken.")
        return value

    def validate_password(self, value):
        validate_password(value)
        return value

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data["username"],
            name_ar=validated_data.get("name_ar", ""),
            email=validated_data.get("email", ""),
            phone=validated_data["phone"],
            address=validated_data.get("address", ""),
            governorate=validated_data.get("governorate", ""),
            city=validated_data.get("city", ""),
            password=validated_data["password"],
            role=validated_data.get("role", User.Role.CLIENT),
        )


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data["username"], password=data["password"])
        if not user:
            raise serializers.ValidationError("Wrong username or password.")
        if not user.is_active:
            raise serializers.ValidationError("This account is disabled.")
        return {"user": user}


class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "username", "name_ar", "email", "phone", "address",
            "governorate", "city", "avatar",
        ]
        extra_kwargs = {
            "username": {"required": False},
            "name_ar": {"required": False, "allow_blank": True},
            "email": {"required": False, "allow_blank": True},
            "phone": {"required": False},
            "address": {"required": False, "allow_blank": True},
            "governorate": {"required": False, "allow_blank": True},
            "city": {"required": False, "allow_blank": True},
            "avatar": {"required": False, "allow_null": True},
        }


class PasswordChangeSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=6)

    def validate(self, attrs):
        user = self.context["request"].user
        if not user.check_password(attrs["current_password"]):
            raise serializers.ValidationError(
                {"current_password": "Wrong current password."}
            )
        validate_password(attrs["new_password"], user=user)
        if attrs["current_password"] == attrs["new_password"]:
            raise serializers.ValidationError(
                {"new_password": "New password must differ from the current one."}
            )
        return attrs

    def save(self, **kwargs):
        user = self.context["request"].user
        user.set_password(self.validated_data["new_password"])
        user.save(update_fields=["password"])
        return user
