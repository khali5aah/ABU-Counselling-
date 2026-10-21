from django.contrib.auth import get_user_model
from rest_framework import serializers

from apps.common.fields import NigerianPhoneField, UsernameField

User = get_user_model()


class OtpRequestSerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()


class OtpVerifySerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()
    request_id = serializers.UUIDField()
    code = serializers.RegexField(r"^\d{6}$", error_messages={"invalid": "Enter the 6-digit code."})


class SetupAccountSerializer(serializers.Serializer):
    setup_token = serializers.CharField(max_length=128)
    username = UsernameField()
    password = serializers.CharField(max_length=128, trim_whitespace=False, write_only=True)


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=64)
    password = serializers.CharField(max_length=128, trim_whitespace=False)

    def validate_username(self, value):
        return (value or "").strip().lower()


class RefreshSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class UserSerializer(serializers.ModelSerializer):
    first_name = serializers.ReadOnlyField()
    last_name = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = ["id", "username", "first_name", "last_name", "date_joined"]
