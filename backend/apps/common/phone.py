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

    value = raw.strip()
    value = value.replace(" ", "").replace("-", "").replace("(", "").replace(")", "").replace(".", "")

    if value.startswith("+234"):
        candidate = value
    elif value.startswith("234"):
        candidate = "+" + value
    elif value.startswith("0") and len(value) == 11:
        candidate = "+234" + value[1:]
    elif len(value) == 10 and value.isdigit():
        candidate = "+234" + value
    else:
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    if not re.fullmatch(r"\+234[789][01]\d{8}", candidate):
        raise InvalidPhoneNumber(PHONE_ERROR_MESSAGE)

    return candidate


def mask_phone(e164: str) -> str:
    cleaned = normalize_ng_phone(e164)
    return cleaned[:4] + "******" + cleaned[-4:]


def phone_hash(e164: str) -> str:
    return hashlib.sha256(normalize_ng_phone(e164).encode("utf-8")).hexdigest()
