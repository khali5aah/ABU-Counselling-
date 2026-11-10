import re

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from apps.common.validators import normalize_matric, normalize_name, normalize_username
from apps.common.phone import InvalidPhoneNumber, normalize_ng_phone


class NigerianPhoneField(serializers.CharField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("max_length", 64)
        kwargs.setdefault("trim_whitespace", True)
        kwargs.setdefault("required", True)
        super().__init__(*args, **kwargs)

    def run_validation(self, data):
        value = super().run_validation(data)
        try:
            return normalize_ng_phone(value)
        except (InvalidPhoneNumber, ValueError, DjangoValidationError) as exc:
            raise serializers.ValidationError(str(exc)) from exc


class RegistrationPhoneField(serializers.CharField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("trim_whitespace", True)
        kwargs.setdefault("required", True)
        super().__init__(*args, **kwargs)

    def run_validation(self, data):
        value = super().run_validation(data)
        phone = re.sub(r"\s", "", value)
        if not re.fullmatch(r"[0-9]{11}", phone):
            raise serializers.ValidationError("Phone number must be exactly 11 digits.")
        return phone


class NameField(serializers.CharField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("max_length", 64)
        kwargs.setdefault("trim_whitespace", True)
        kwargs.setdefault("required", True)
        super().__init__(*args, **kwargs)

    def run_validation(self, data):
        value = super().run_validation(data)
        try:
            return normalize_name(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(str(exc)) from exc


class MatricField(serializers.CharField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("trim_whitespace", True)
        kwargs.setdefault("required", True)
        super().__init__(*args, **kwargs)

    def run_validation(self, data):
        value = super().run_validation(data)
        try:
            return normalize_matric(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.messages) from exc


class UsernameField(serializers.CharField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("max_length", 64)
        kwargs.setdefault("trim_whitespace", True)
        kwargs.setdefault("required", True)
        super().__init__(*args, **kwargs)

    def run_validation(self, data):
        value = super().run_validation(data)
        try:
            return normalize_username(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(str(exc)) from exc
