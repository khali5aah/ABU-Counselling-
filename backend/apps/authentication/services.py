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
from rest_framework_simplejwt.token_blacklist.models import (
    BlacklistedToken,
    OutstandingToken,
)
from rest_framework_simplejwt.tokens import RefreshToken

from apps.authentication.models import PasswordReset, PhoneVerification, User
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
from apps.common.phone import mask_phone, phone_hash, normalize_ng_phone, InvalidPhoneNumber
from apps.registrations.codes import hash_signup_code
from apps.registrations.models import StudentRegistration

logger = logging.getLogger("chdc")
GENERIC_OTP_MESSAGE = "If this number is registered and not yet set up, a verification code has been sent by SMS."
GENERIC_PASSWORD_RESET_MESSAGE = (
    "If an account exists for this phone number, a password reset code has been sent by SMS."
)


def hash_code(verification_id, code):
    return hmac.new(settings.SECRET_KEY.encode(), f"{verification_id}:{code}".encode(), hashlib.sha256).hexdigest()


def hash_password_reset_code(reset_id, code):
    value = f"password-reset:{reset_id}:{code}".encode()
    return hmac.new(settings.SECRET_KEY.encode(), value, hashlib.sha256).hexdigest()


def hash_setup_token(token):
    return hashlib.sha256(token.encode()).hexdigest()


def request_otp(phone: str) -> dict:
    # 1. Normalize phone number to match database formatting consistently
    try:
        phone = normalize_ng_phone(phone)
    except InvalidPhoneNumber:
        raise serializers.ValidationError({"phone_number": ["Invalid phone number format."]})

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

    local_phone = f"0{phone[-10:]}"
    registration = StudentRegistration.objects.filter(
        phone_number__in=[phone, local_phone]
    ).first()
    eligible = registration is not None and not User.objects.filter(registration=registration).exists()

    if (
        eligible
        and settings.DEBUG
        and settings.OTP_PROVIDER == "console"
        and registration.signup_code_hash
        and registration.signup_code_used_at is None
        and registration.signup_code_expires_at is not None
        and timezone.now() < registration.signup_code_expires_at
    ):
        with transaction.atomic():
            PhoneVerification.objects.filter(
                registration=registration,
                verified_at__isnull=True,
                invalidated_at__isnull=True,
            ).update(invalidated_at=timezone.now())
            verification = PhoneVerification.objects.create(
                registration=registration,
                phone_number=phone,
                code_hash="",
                expires_at=registration.signup_code_expires_at,
                max_attempts=settings.OTP_MAX_ATTEMPTS,
                is_registration_code=True,
            )
        return {
            "request_id": str(verification.id),
            "message": "Enter the 6-digit code shown after web registration. It expires in 15 minutes.",
            "expires_in": max(
                0, int((registration.signup_code_expires_at - timezone.now()).total_seconds())
            ),
            "resend_after": 0,
            "is_registration_code": True,
        }
    
    if not eligible:
        if settings.DEBUG and settings.OTP_PROVIDER == "console":
            raise serializers.ValidationError(
                {"phone_number": ["This number is not registered for account setup."]}
            )
        logger.info("otp request not eligible phone=%s", mask_phone(phone))
        return {
            "request_id": str(uuid4()),
            "message": GENERIC_OTP_MESSAGE,
            "expires_in": settings.OTP_TTL_SECONDS,
            "resend_after": settings.OTP_RESEND_COOLDOWN_SECONDS,
        }

    use_test_code = (
        settings.DEBUG
        and settings.OTP_PROVIDER == "console"
        and phone in settings.OTP_DEV_TEST_PHONES
    )
    code = settings.OTP_DEV_CODE if use_test_code else f"{secrets.randbelow(10**6):06d}"
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
        get_otp_provider().send_code(phone, code, settings.OTP_TTL_SECONDS)
    except OtpDeliveryError:
        logger.error("otp delivery failed phone=%s", mask_phone(phone))

    return {
        "request_id": str(verification.id),
        "message": GENERIC_OTP_MESSAGE,
        "expires_in": settings.OTP_TTL_SECONDS,
        "resend_after": settings.OTP_RESEND_COOLDOWN_SECONDS,
    }


def request_password_reset(phone: str) -> dict:
    try:
        phone = normalize_ng_phone(phone)
    except InvalidPhoneNumber:
        raise serializers.ValidationError({"phone_number": ["Invalid phone number format."]})

    phone_key = phone_hash(phone)
    now_seconds = time.time()
    cooldown_key = f"password-reset:cooldown:{phone_key}"
    window_key = f"password-reset:window:{phone_key}"
    until = cache.get(cooldown_key)
    if until and until > now_seconds:
        raise RateLimitedError(
            retry_after=max(1, int(math.ceil(until - now_seconds)))
        )
    window = cache.get(window_key) or {"start": now_seconds, "count": 0}
    if window["count"] >= int(settings.OTP_MAX_REQUESTS_PER_PHONE_PER_HOUR):
        retry_after = max(1, int(math.ceil(window["start"] + 3600 - now_seconds)))
        raise RateLimitedError(retry_after=retry_after)
    cache.set(
        cooldown_key,
        now_seconds + settings.OTP_RESEND_COOLDOWN_SECONDS,
        timeout=settings.OTP_RESEND_COOLDOWN_SECONDS,
    )
    window["count"] += 1
    cache.set(
        window_key,
        window,
        timeout=max(1, int(window["start"] + 3600 - now_seconds)),
    )

    reset_id = uuid4()
    reset = None
    with transaction.atomic():
        user = (
            User.objects.select_for_update()
            .filter(registration__phone_number__in=[phone, f"0{phone[-10:]}"], is_active=True)
            .first()
        )
        if user:
            code = f"{secrets.randbelow(10**6):06d}"
            expires_at = timezone.now() + timedelta(
                seconds=settings.PASSWORD_RESET_OTP_TTL_SECONDS
            )
            PasswordReset.objects.filter(
                phone_number=phone, is_used=False
            ).update(is_used=True)
            reset = PasswordReset.objects.create(
                id=reset_id,
                phone_number=phone,
                otp_code=hash_password_reset_code(reset_id, code),
                expires_at=expires_at,
            )

    if reset is not None:
        try:
            get_otp_provider().send_code(
                phone,
                code,
                settings.PASSWORD_RESET_OTP_TTL_SECONDS,
                purpose="password reset code",
            )
        except OtpDeliveryError:
            logger.error("password reset otp delivery failed phone=%s", mask_phone(phone))
        return {
            "request_id": str(reset.id),
            "message": GENERIC_PASSWORD_RESET_MESSAGE,
            "expires_in": settings.PASSWORD_RESET_OTP_TTL_SECONDS,
        }

    logger.info("password reset requested for unknown phone=%s", mask_phone(phone))
    return {
        "request_id": str(reset_id),
        "message": GENERIC_PASSWORD_RESET_MESSAGE,
        "expires_in": settings.PASSWORD_RESET_OTP_TTL_SECONDS,
    }


def confirm_password_reset(phone: str, request_id, code: str, new_password: str) -> None:
    now = timezone.now()
    outcome = None
    with transaction.atomic():
        reset = (
            PasswordReset.objects.select_for_update()
            .filter(id=request_id, phone_number=phone)
            .first()
        )
        if reset is None or reset.is_used:
            outcome = "invalid"
        elif now >= reset.expires_at:
            reset.is_used = True
            reset.save(update_fields=["is_used"])
            outcome = "expired"
        elif reset.attempts >= settings.OTP_MAX_ATTEMPTS:
            reset.is_used = True
            reset.save(update_fields=["is_used"])
            outcome = "attempts"
        elif not hmac.compare_digest(
            reset.otp_code, hash_password_reset_code(reset.id, code)
        ):
            reset.attempts += 1
            if reset.attempts >= settings.OTP_MAX_ATTEMPTS:
                reset.is_used = True
                reset.save(update_fields=["attempts", "is_used"])
                outcome = "attempts"
            else:
                reset.save(update_fields=["attempts"])
                outcome = ("wrong", settings.OTP_MAX_ATTEMPTS - reset.attempts)
        else:
            user = (
                User.objects.select_for_update()
                .filter(registration__phone_number=phone, is_active=True)
                .first()
            )
            if user is None:
                outcome = "invalid"
            else:
                try:
                    from django.contrib.auth.password_validation import validate_password

                    validate_password(new_password, user=user)
                except DjangoValidationError as exc:
                    outcome = ("password", list(exc.messages))
                else:
                    user.set_password(new_password)
                    user.save(update_fields=["password"])
                    for token in OutstandingToken.objects.filter(user=user):
                        BlacklistedToken.objects.get_or_create(token=token)
                    reset.is_used = True
                    reset.save(update_fields=["is_used"])
                    outcome = "ok"

    if outcome == "invalid":
        raise InvalidOtpError()
    if outcome == "expired":
        raise OtpExpiredError()
    if outcome == "attempts":
        raise OtpAttemptsExceededError()
    if isinstance(outcome, tuple) and outcome[0] == "wrong":
        raise InvalidOtpError(extra={"attempts_remaining": outcome[1]})
    if isinstance(outcome, tuple) and outcome[0] == "password":
        raise serializers.ValidationError({"new_password": outcome[1]})
    if outcome != "ok":
        raise InvalidOtpError()


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
            registration = StudentRegistration.objects.select_for_update().get(
                pk=verification.registration_id
            )
            if registration.status == StudentRegistration.Status.PENDING:
                registration.status = StudentRegistration.Status.EXPIRED
                registration.save(update_fields=["status"])
            outcome = ("expired", None)
        elif verification.is_registration_code:
            registration = StudentRegistration.objects.select_for_update().get(
                pk=verification.registration_id
            )
            if (
                registration.signup_code_used_at is not None
            ):
                outcome = ("invalid", None)
            elif (
                registration.signup_code_expires_at is None
                or now >= registration.signup_code_expires_at
            ):
                registration.status = StudentRegistration.Status.EXPIRED
                registration.save(update_fields=["status"])
                outcome = ("expired", None)
            elif registration.signup_code_attempts >= verification.max_attempts:
                outcome = ("attempts", None)
            elif not hmac.compare_digest(
                registration.signup_code_hash,
                hash_signup_code(registration.id, code),
            ):
                registration.signup_code_attempts += 1
                registration.save(update_fields=["signup_code_attempts"])
                remaining = verification.max_attempts - registration.signup_code_attempts
                outcome = ("attempts", None) if remaining <= 0 else ("wrong", remaining)
            else:
                token = secrets.token_urlsafe(32)
                verification.verified_at = now
                verification.setup_token_hash = hash_setup_token(token)
                verification.setup_token_expires_at = now + timedelta(seconds=settings.SETUP_TOKEN_TTL_SECONDS)
                verification.save()
                outcome = ("ok", token)
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
                    if verification.is_registration_code:
                        verification.registration.signup_code_used_at = now
                    verification.registration.status = StudentRegistration.Status.COMPLETED
                    verification.registration.save(
                        update_fields=["signup_code_used_at", "status"]
                    )
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