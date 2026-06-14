from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.validators import RegexValidator
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
    # Mark optional fields explicitly — DRF infers required=True for
    # model CharFields even when `blank=True` is set, which used to
    # send a misleading "this field is required" back to the mobile.
    email = serializers.EmailField(required=False, allow_blank=True)
    name_ar = serializers.CharField(required=False, allow_blank=True, max_length=120)
    address = serializers.CharField(required=False, allow_blank=True, max_length=255)
    governorate = serializers.CharField(required=False, allow_blank=True, max_length=20)
    city = serializers.CharField(required=False, allow_blank=True, max_length=80)
    # Override the username field to replace Django's default
    # UnicodeUsernameValidator — its message ("letters, numbers, and
    # @/./+/-/_") is opaque to end-users. Our two validators surface
    # "no spaces" specifically, then the broader character constraint.
    username = serializers.CharField(
        max_length=150,
        validators=[
            RegexValidator(
                regex=r"^\S+$",
                message="Username can't contain spaces. Use letters, "
                        "numbers, or _ — pick the display name in the "
                        "separate field.",
            ),
            RegexValidator(
                regex=r"^[A-Za-z0-9_.@+\-]+$",
                message="Username can only contain letters, numbers, "
                        "or _ . + - @.",
            ),
        ],
    )

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
        # Character-set validation lives on the field-level validators
        # above so the friendly "no spaces" message fires first; this
        # one handles uniqueness.
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("Username is already taken.")
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
