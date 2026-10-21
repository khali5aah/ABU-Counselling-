import hashlib
import hmac
import logging
import math
import secrets
import time
from datetime import timedelta
from uuid import uuid4

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from apps.authentication.models import PhoneVerification, User
from apps.authentication.otp.providers import OtpDeliveryError, get_otp_provider
from apps.common.exceptions import (
    DuplicateError,
    InvalidCredentialsError,
    InvalidOtpError,
    OtpAttemptsExceededError,
    OtpExpiredError,
    RateLimitedError,
    SetupTokenInvalidError,
)
from apps.common.phone import mask_phone, phone_hash
from apps.registrations.models import StudentRegistration

logger = logging.getLogger("crownbird")
GENERIC_OTP_MESSAGE = "If this number is registered and not yet set up, a verification code has been sent by SMS."


def hash_code(verification_id, code):
    return hmac.new(settings.SECRET_KEY.encode(), f"{verification_id}:{code}".encode(), hashlib.sha256).hexdigest()


def hash_setup_token(token):
    return hashlib.sha256(token.encode()).hexdigest()


def request_otp(phone: str) -> dict:
    phone_key = phone_hash(phone)
    now = time.time()
    cooldown_key = f"otp:cooldown:{phone_key}"
    window_key = f"otp:window:{phone_key}"

    until = cache.get(cooldown_key)
    if until and until > now:
        retry_after = max(1, int(math.ceil(until - now)))
        raise RateLimitedError(retry_after=retry_after)

    window = cache.get(window_key) or {"start": now, "count": 0}
    if window.get("count", 0) >= int(settings.OTP_MAX_REQUESTS_PER_PHONE_PER_HOUR):
        retry_after = max(1, int(math.ceil(window["start"] + 3600 - now)))
        raise RateLimitedError(retry_after=retry_after)

    cache.set(cooldown_key, now + settings.OTP_RESEND_COOLDOWN_SECONDS, timeout=settings.OTP_RESEND_COOLDOWN_SECONDS)
    window["count"] = int(window.get("count", 0)) + 1
    cache.set(window_key, window, timeout=max(1, int(window["start"] + 3600 - now)))

    registration = StudentRegistration.objects.filter(phone_number=phone).first()
    eligible = registration is not None and not User.objects.filter(registration=registration).exists()
    if not eligible:
        logger.info("otp request not eligible phone=%s", mask_phone(phone))
        return {
            "request_id": str(uuid4()),
            "message": GENERIC_OTP_MESSAGE,
            "expires_in": settings.OTP_TTL_SECONDS,
            "resend_after": settings.OTP_RESEND_COOLDOWN_SECONDS,
        }

    code = f"{secrets.randbelow(10**6):06d}"
    with transaction.atomic():
        PhoneVerification.objects.filter(
            registration=registration,
            verified_at__isnull=True,
            invalidated_at__isnull=True,
        ).update(invalidated_at=timezone.now())
        verification = PhoneVerification(
            id=uuid4(),
            registration=registration,
            phone_number=phone,
            expires_at=timezone.now() + timedelta(seconds=settings.OTP_TTL_SECONDS),
            max_attempts=settings.OTP_MAX_ATTEMPTS,
        )
        verification.code_hash = hash_code(verification.id, code)
        verification.save()

    try:
        get_otp_provider().send_code(phone, code)
    except OtpDeliveryError:
        logger.error("otp delivery failed phone=%s", mask_phone(phone))

    return {
        "request_id": str(verification.id),
        "message": GENERIC_OTP_MESSAGE,
        "expires_in": settings.OTP_TTL_SECONDS,
        "resend_after": settings.OTP_RESEND_COOLDOWN_SECONDS,
    }


def verify_otp(phone: str, request_id, code: str) -> dict:
    now = timezone.now()
    outcome = None
    remaining = None
    token = None

    with transaction.atomic():
        verification = PhoneVerification.objects.select_for_update().filter(id=request_id, phone_number=phone).first()
        if verification is None or verification.invalidated_at or verification.verified_at is not None:
            outcome = ("invalid", None)
        elif verification.attempts >= verification.max_attempts:
            outcome = ("attempts", None)
        elif now >= verification.expires_at:
            outcome = ("expired", None)
        elif not hmac.compare_digest(verification.code_hash, hash_code(verification.id, code)):
            verification.attempts += 1
            verification.save(update_fields=["attempts"])
            remaining = verification.max_attempts - verification.attempts
            outcome = ("attempts", None) if remaining <= 0 else ("wrong", remaining)
        else:
            token = secrets.token_urlsafe(32)
            verification.verified_at = now
            verification.setup_token_hash = hash_setup_token(token)
            verification.setup_token_expires_at = now + timedelta(seconds=settings.SETUP_TOKEN_TTL_SECONDS)
            verification.save()
            outcome = ("ok", token)

    if outcome[0] == "invalid":
        raise InvalidOtpError()
    if outcome[0] == "wrong":
        raise InvalidOtpError(extra={"attempts_remaining": remaining})
    if outcome[0] == "attempts":
        raise OtpAttemptsExceededError()
    if outcome[0] == "expired":
        raise OtpExpiredError()
    if outcome[0] == "ok":
        return {"setup_token": token, "expires_in": settings.SETUP_TOKEN_TTL_SECONDS}
    raise InvalidOtpError()


def setup_account(setup_token: str, username: str, password: str):
    now = timezone.now()
    outcome = None

    with transaction.atomic():
        verification = (
            PhoneVerification.objects.select_for_update()
            .select_related("registration")
            .filter(setup_token_hash=hash_setup_token(setup_token))
            .first()
        )

        if verification is None or verification.setup_token_used_at or verification.setup_token_expires_at is None or now >= verification.setup_token_expires_at:
            outcome = "token_invalid"
        elif User.objects.filter(registration=verification.registration).exists():
            verification.setup_token_used_at = now
            verification.save(update_fields=["setup_token_used_at"])
            outcome = "token_invalid"
        else:
            try:
                from django.contrib.auth.password_validation import validate_password

                validate_password(password, user=User(username=username))
            except DjangoValidationError as exc:
                outcome = ("password", list(exc.messages))
            if outcome is None and User.objects.filter(username=username).exists():
                outcome = "duplicate"
            if outcome is None:
                try:
                    with transaction.atomic():
                        user = User.objects.create_user(username=username, password=password, registration=verification.registration)
                except IntegrityError:
                    if User.objects.filter(username=username).exists():
                        outcome = "duplicate"
                    else:
                        outcome = "token_invalid"
                else:
                    verification.setup_token_used_at = now
                    verification.save(update_fields=["setup_token_used_at"])
                    outcome = ("ok", user)

    if outcome == "token_invalid":
        raise SetupTokenInvalidError()
    if isinstance(outcome, tuple) and outcome[0] == "password":
        raise serializers.ValidationError({"password": outcome[1]})
    if outcome == "duplicate":
        raise DuplicateError(fields={"username": ["This username is taken."]})
    if isinstance(outcome, tuple) and outcome[0] == "ok":
        return outcome[1]
    raise SetupTokenInvalidError()


def issue_tokens(user) -> dict:
    refresh = RefreshToken.for_user(user)
    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user": UserSerializer(user).data,
    }


from apps.authentication.serializers import UserSerializer
