import logging

import requests
from django.conf import settings

crownbird_logger = logging.getLogger("crownbird")
crownbird_logger.propagate = True
logger = logging.getLogger("crownbird.otp")
logger.propagate = True


class OtpDeliveryError(Exception):
    pass


SMS_TEMPLATE = "Your Crownbird verification code is {code}. It expires in 5 minutes. Do not share it with anyone."


class BaseOtpProvider:
    def send_code(self, phone_e164: str, code: str) -> None:
        raise NotImplementedError


class ConsoleOtpProvider(BaseOtpProvider):
    def send_code(self, phone_e164: str, code: str) -> None:
        logger.warning("[DEV OTP] phone=%s code=%s", phone_e164, code)


class TermiiOtpProvider(BaseOtpProvider):
    def send_code(self, phone_e164: str, code: str) -> None:
        base_url = settings.TERMII_BASE_URL.rstrip("/")
        url = base_url if base_url.endswith("/api/sms/send") else f"{base_url}/api/sms/send"
        payload = {
            "api_key": settings.TERMII_API_KEY,
            "to": phone_e164.lstrip("+"),
            "from": settings.TERMII_SENDER_ID,
            "sms": SMS_TEMPLATE.format(code=code),
            "type": "plain",
            "channel": settings.TERMII_CHANNEL,
        }
        try:
            response = requests.post(url, json=payload, timeout=10)
        except requests.RequestException as exc:
            raise OtpDeliveryError(f"Termii send failed: HTTP {exc}") from exc

        try:
            data = response.json()
        except ValueError as exc:
            raise OtpDeliveryError(f"Termii send failed: HTTP {response.status_code}") from exc

        if response.status_code >= 400 or not data.get("message_id"):
            raise OtpDeliveryError(f"Termii send failed: HTTP {response.status_code}")


def get_otp_provider() -> BaseOtpProvider:
    provider_map = {
        "console": ConsoleOtpProvider,
        "termii": TermiiOtpProvider,
    }
    return provider_map[settings.OTP_PROVIDER]()
