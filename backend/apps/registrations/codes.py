import hashlib
import hmac

from django.conf import settings


def registration_signup_codes_enabled():
    return settings.DEMO_SIGNUP_CODES_ENABLED or (
        settings.DEBUG and settings.OTP_PROVIDER == "console"
    )


def hash_signup_code(registration_id, code):
    value = f"{registration_id}:{code}".encode()
    return hmac.new(settings.SECRET_KEY.encode(), value, hashlib.sha256).hexdigest()
