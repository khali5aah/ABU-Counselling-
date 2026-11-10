import hashlib
import hmac

from django.conf import settings


def hash_signup_code(registration_id, code):
    value = f"{registration_id}:{code}".encode()
    return hmac.new(settings.SECRET_KEY.encode(), value, hashlib.sha256).hexdigest()
