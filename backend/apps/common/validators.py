import re

from django.core.exceptions import ValidationError


NAME_PATTERN = re.compile(r"^[A-Za-z][A-Za-z' -]{0,49}$")
USERNAME_PATTERN = re.compile(r"^[a-z][a-z0-9_]{2,29}$")


def normalize_name(value):
    if value is None:
        raise ValidationError("Enter a valid name using letters, spaces, apostrophes or hyphens.")
    text = " ".join(str(value).strip().split())
    if not text or not NAME_PATTERN.fullmatch(text):
        raise ValidationError("Enter a valid name using letters, spaces, apostrophes or hyphens.")
    return text


def normalize_matric(value):
    if value is None:
        raise ValidationError("Matric number must be exactly 9 characters.")
    text = str(value).strip()
    if len(text) != 9:
        raise ValidationError("Matric number must be exactly 9 characters.")
    return text.upper()


def normalize_username(value):
    if value is None:
        raise ValidationError("Enter a valid username beginning with a letter and containing only lowercase letters, numbers, and underscores.")
    text = str(value).strip().lower()
    if not text or not USERNAME_PATTERN.fullmatch(text):
        raise ValidationError("Enter a valid username beginning with a letter and containing only lowercase letters, numbers, and underscores.")
    return text
