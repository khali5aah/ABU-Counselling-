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


class PasswordResetRequestSerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    phone_number = NigerianPhoneField()
    request_id = serializers.UUIDField()
    otp_code = serializers.RegexField(
        r"^\d{6}$", error_messages={"invalid": "Enter the 6-digit code."}
    )
    new_password = serializers.CharField(
        max_length=128, trim_whitespace=False, write_only=True
    )


class SetupAccountSerializer(serializers.Serializer):
    setup_token = serializers.CharField(max_length=128)
    username = UsernameField()
    password = serializers.CharField(max_length=128, trim_whitespace=False, write_only=True)
    has_consented = serializers.BooleanField(required=True)

    def validate_has_consented(self, value):
        if not value:
            raise serializers.ValidationError(
                "You must accept the NDPR consent policy to create an account."
            )
        return value


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
    phone_number = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = ["id", "username", "phone_number", "date_joined"]
