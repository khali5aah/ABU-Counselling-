from django.db import IntegrityError, transaction
from rest_framework import serializers

from apps.common.exceptions import DuplicateError
from apps.common.fields import MatricField, NameField, NigerianPhoneField
from apps.registrations.models import StudentRegistration


class RegistrationCreateSerializer(serializers.Serializer):
    first_name = NameField()
    last_name = NameField()
    matric_number = MatricField()
    phone_number = NigerianPhoneField()

    def create(self, validated_data):
        matric_number = validated_data["matric_number"]
        phone_number = validated_data["phone_number"]

        duplicates = {}
        if StudentRegistration.objects.filter(matric_number=matric_number).exists():
            duplicates["matric_number"] = ["This matric number is already registered."]
        if StudentRegistration.objects.filter(phone_number=phone_number).exists():
            duplicates["phone_number"] = ["This phone number is already registered."]

        if duplicates:
            raise DuplicateError(fields=duplicates)

        try:
            with transaction.atomic():
                return StudentRegistration.objects.create(**validated_data)
        except IntegrityError:
            recomputed = {}
            if StudentRegistration.objects.filter(matric_number=matric_number).exists():
                recomputed["matric_number"] = ["This matric number is already registered."]
            if StudentRegistration.objects.filter(phone_number=phone_number).exists():
                recomputed["phone_number"] = ["This phone number is already registered."]
            if recomputed:
                raise DuplicateError(fields=recomputed)
            raise DuplicateError(fields={"non_field_errors": ["Some details are already registered."]})


class RegistrationResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudentRegistration
        fields = ["first_name", "last_name", "matric_number", "phone_number", "created_at"]
