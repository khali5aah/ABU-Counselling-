"""Development-only store of recently sent OTP codes (console provider only).

Codes live in the shared cache so every API worker sees them, and expire with the OTP.
"""
from datetime import timedelta

from django.conf import settings
from django.core.cache import cache
from django.utils import timezone

CACHE_KEY = "dev_otp_codes"
MAX_CODES = 20


def dev_codes_enabled() -> bool:
    return settings.DEBUG and settings.OTP_PROVIDER == "console"


def remember_code(phone_e164: str, code: str) -> None:
    if not dev_codes_enabled():
        return
    now = timezone.now()
    entry = {
        "phone_number": phone_e164,
        "code": code,
        "sent_at": now.isoformat(),
        "expires_at": (now + timedelta(seconds=settings.OTP_TTL_SECONDS)).isoformat(),
    }
    codes = [entry, *recent_codes()][:MAX_CODES]
    cache.set(CACHE_KEY, codes, timeout=settings.OTP_TTL_SECONDS)


def recent_codes(phone_e164: str | None = None) -> list[dict]:
    now = timezone.now().isoformat()
    codes = [c for c in cache.get(CACHE_KEY, []) if c["expires_at"] > now]
    if phone_e164:
        codes = [c for c in codes if c["phone_number"] == phone_e164]
    return codes
