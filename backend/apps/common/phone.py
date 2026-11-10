import re
import hashlib


PHONE_ERROR_MESSAGE = "Enter a valid Nigerian mobile number, e.g. 08031234567."


class InvalidPhoneNumber(ValueError):
    pass


def normalize_ng_phone(raw: str) -> str:
    if raw is None:
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    if not isinstance(raw, str):
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    if any(character.isalpha() for character in raw):
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    value = re.sub(r"[^0-9+]", "", raw)
    if value.count("+") > 1 or ("+" in value and not value.startswith("+")):
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    if value.startswith("+234"):
        candidate = value
    elif value.startswith("0") and len(value) == 11:
        candidate = "+234" + value[1:]
    else:
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    if not re.fullmatch(r"\+234\d{10}", candidate):
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    return candidate


def mask_phone(e164: str) -> str:
    if isinstance(e164, str) and re.fullmatch(r"\d{11}", e164):
        return e164[:3] + "******" + e164[-2:]
    cleaned = normalize_ng_phone(e164)
    return cleaned[:4] + "******" + cleaned[-4:]


def phone_hash(e164: str) -> str:
    return hashlib.sha256(normalize_ng_phone(e164).encode("utf-8")).hexdigest()
