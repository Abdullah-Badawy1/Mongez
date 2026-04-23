from django.contrib.auth import authenticate
from rest_framework import serializers
from .models import User

#for displaying user data only 
class UserSerializer(serializers.ModelSerializer):
    
    class Meta:
        model  = User
        fields = ["id", "username", "phone", "address", "role", "date_joined"]
        read_only_fields = fields

#for creating a new account
class RegisterSerializer(serializers.ModelSerializer):
    
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ["username", "phone", "address", "password", "role"]

    def validate_role(self, value):
        
        if value == User.Role.ADMIN:
            raise serializers.ValidationError("You cannot register as admin.")
        return value

    def create(self, validated_data):
        #usinge create_user to hash the password 
        return User.objects.create_user(
            username = validated_data["username"],
            phone    = validated_data["phone"],
            address  = validated_data.get("address", ""),
            password = validated_data["password"],
            role     = validated_data.get("role", User.Role.CLIENT),
        )


class LoginSerializer(serializers.Serializer):
   
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        # using authenticate to check username and password and return none if wrong
        user = authenticate(username=data["username"], password=data["password"])
        if not user:
            raise serializers.ValidationError("Wrong username or password.")
        if not user.is_active:
            raise serializers.ValidationError("This account is disabled.")
        return {"user": user}


class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model  = User
        fields = ["username", "phone", "address"]
