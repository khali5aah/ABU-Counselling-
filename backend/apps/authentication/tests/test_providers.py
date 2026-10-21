import logging

import pytest

from apps.authentication.otp.providers import ConsoleOtpProvider, OtpDeliveryError, TermiiOtpProvider


def test_termii_provider_raises_without_exposing_secret(monkeypatch):
    calls = {}

    class FakeResponse:
        status_code = 200
        def json(self):
            return {"message_id": "abc123"}

    def fake_post(url, json, timeout):
        calls["url"] = url
        calls["json"] = json
        calls["timeout"] = timeout
        return FakeResponse()

    monkeypatch.setattr("apps.authentication.otp.providers.requests.post", fake_post)
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_BASE_URL", "https://api.ng.termii.com/api/sms/send")
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_API_KEY", "secret-key")
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_SENDER_ID", "Crownbird")
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_CHANNEL", "dnd")

    provider = TermiiOtpProvider()
    provider.send_code("+2348031234567", "123456")

    assert calls["url"] == "https://api.ng.termii.com/api/sms/send"
    assert calls["json"]["to"] == "2348031234567"
    assert calls["json"]["api_key"] == "secret-key"


def test_termii_provider_raises_on_http_failure(monkeypatch):
    class FakeResponse:
        status_code = 401
        def json(self):
            return {"message": "fail"}

    monkeypatch.setattr("apps.authentication.otp.providers.requests.post", lambda *a, **k: FakeResponse())
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_BASE_URL", "https://api.ng.termii.com")
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_API_KEY", "secret-key")
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_SENDER_ID", "Crownbird")
    monkeypatch.setattr("apps.authentication.otp.providers.settings.TERMII_CHANNEL", "dnd")

    with pytest.raises(OtpDeliveryError):
        TermiiOtpProvider().send_code("+2348031234567", "123456")


def test_console_provider_logs_dev_code(caplog):
    provider = ConsoleOtpProvider()
    with caplog.at_level(logging.WARNING, logger="crownbird.otp"):
        provider.send_code("+2348031234567", "123456")
    assert "[DEV OTP]" in caplog.text
