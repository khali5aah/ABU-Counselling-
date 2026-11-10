import secrets
from datetime import timedelta

from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework import serializers

from apps.common.exceptions import DuplicateError
from apps.common.fields import MatricField, NameField, RegistrationPhoneField
from apps.authentication.models import PhoneVerification
from apps.registrations.codes import hash_signup_code
from apps.registrations.models import StudentRegistration

REGISTRATION_OTP_TTL_SECONDS = 15 * 60


class RegistrationCreateSerializer(serializers.Serializer):
    first_name = NameField()
    last_name = NameField()
    matric_number = MatricField()
    phone_number = RegistrationPhoneField()
    has_consented = serializers.BooleanField(required=True)

    def validate_has_consented(self, value):
        if not value:
            raise serializers.ValidationError(
                "You must accept the NDPR consent policy to proceed."
            )
        return value

    def create(self, validated_data):
        matric_number = validated_data["matric_number"]
        phone_number = validated_data["phone_number"]

        signup_code = (
            f"{secrets.randbelow(10**6):06d}"
            if settings.DEBUG and settings.OTP_PROVIDER == "console"
            else None
        )
        try:
            with transaction.atomic():
                registration = (
                    StudentRegistration.objects.select_for_update()
                    .filter(phone_number=phone_number)
                    .first()
                )
                duplicates = {}
                if registration and registration.status not in {
                    StudentRegistration.Status.PENDING,
                    StudentRegistration.Status.EXPIRED,
                }:
                    duplicates["phone_number"] = ["This phone number is already registered."]
                matric_query = StudentRegistration.objects.filter(
                    matric_number=matric_number
                )
                if registration:
                    matric_query = matric_query.exclude(pk=registration.pk)
                if matric_query.exists():
                    duplicates["matric_number"] = ["This matric number is already registered."]
                if duplicates:
                    raise DuplicateError(fields=duplicates)

                now = timezone.now()
                code_expiry = (
                    now + timedelta(seconds=REGISTRATION_OTP_TTL_SECONDS)
                    if signup_code is not None
                    else None
                )
                if registration is None:
                    registration = StudentRegistration.objects.create(
                        **validated_data,
                        status=StudentRegistration.Status.PENDING,
                        signup_code_expires_at=code_expiry,
                    )
                else:
                    registration.first_name = validated_data["first_name"]
                    registration.last_name = validated_data["last_name"]
                    registration.matric_number = matric_number
                    registration.phone_number = phone_number
                    registration.has_consented = validated_data["has_consented"]
                    registration.status = StudentRegistration.Status.PENDING
                    registration.signup_code_hash = ""
                    registration.signup_code_expires_at = code_expiry
                    registration.signup_code_used_at = None
                    registration.signup_code_attempts = 0
                    registration.save()
                    PhoneVerification.objects.filter(
                        registration=registration,
                        invalidated_at__isnull=True,
                    ).update(invalidated_at=now)
                    PhoneVerification.objects.filter(
                        registration=registration,
                        setup_token_hash__isnull=False,
                        setup_token_used_at__isnull=True,
                    ).update(setup_token_used_at=now)

                if signup_code is not None:
                    registration.signup_code_hash = hash_signup_code(
                        registration.id, signup_code
                    )
                    registration.save(update_fields=["signup_code_hash"])
                    registration._signup_code = signup_code
                return registration
        except IntegrityError:
            recomputed = {}
            if StudentRegistration.objects.filter(matric_number=matric_number).exists():
                recomputed["matric_number"] = ["This matric number is already registered."]
            existing = StudentRegistration.objects.filter(phone_number=phone_number).first()
            if existing and existing.status not in {
                StudentRegistration.Status.PENDING,
                StudentRegistration.Status.EXPIRED,
            }:
                recomputed["phone_number"] = ["This phone number is already registered."]
            if recomputed:
                raise DuplicateError(fields=recomputed)
            raise DuplicateError(fields={"non_field_errors": ["Some details are already registered."]})


class RegistrationResponseSerializer(serializers.ModelSerializer):
    signup_code = serializers.SerializerMethodField()

    class Meta:
        model = StudentRegistration
        fields = [
            "first_name",
            "last_name",
            "matric_number",
            "phone_number",
            "created_at",
            "signup_code",
        ]

    def get_signup_code(self, obj):
        return getattr(obj, "_signup_code", None)