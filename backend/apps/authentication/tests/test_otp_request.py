import re

import pytest
from django.conf import settings
from rest_framework.throttling import ScopedRateThrottle

from apps.registrations.models import StudentRegistration


@pytest.mark.django_db
def test_request_otp_for_registered_number_sends_code_and_stores_verification(api_client, registration, sent_codes):
    response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234567"}, format="json")
    assert response.status_code == 200
    assert set(response.data) == {"request_id", "message", "expires_in", "resend_after"}
    assert response.data["message"] == "If this number is registered and not yet set up, a verification code has been sent by SMS."
    assert len(sent_codes) == 1
    phone, code, _ = sent_codes[0]
    assert phone == "+2348031234567"
    assert re.fullmatch(r"\d{6}", code)
    assert response.data["request_id"]


@pytest.mark.django_db
def test_request_otp_for_unregistered_number_returns_generic_response(api_client, sent_codes):
    response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234568"}, format="json")
    assert response.status_code == 200
    assert response.data["message"] == "If this number is registered and not yet set up, a verification code has been sent by SMS."
    assert sent_codes == []

    verification = api_client.post(
        "/api/v1/auth/otp/verify/",
        {
            "phone_number": "08031234568",
            "request_id": response.data["request_id"],
            "code": "123456",
        },
        format="json",
    )
    assert verification.status_code == 400
    assert verification.data["error"]["code"] == "invalid_otp"


@pytest.mark.django_db
def test_development_otp_request_rejects_unregistered_number(
    api_client, sent_codes, monkeypatch
):
    from django.conf import settings

    monkeypatch.setattr(settings, "DEBUG", True)
    monkeypatch.setattr(settings, "OTP_PROVIDER", "console")
    response = api_client.post(
        "/api/v1/auth/otp/request/",
        {"phone_number": "08031234568"},
        format="json",
    )
    assert response.status_code == 400
    assert (
        response.data["error"]["fields"]["phone_number"][0]
        == "This number is not registered for account setup."
    )
    assert sent_codes == []


@pytest.mark.django_db
def test_development_code_verifies_only_registered_phone(
    api_client, registration, sent_codes, monkeypatch
):
    from django.conf import settings

    monkeypatch.setattr(settings, "DEBUG", True)
    monkeypatch.setattr(settings, "OTP_PROVIDER", "console")
    monkeypatch.setattr(settings, "OTP_DEV_CODE", "123456")
    monkeypatch.setattr(settings, "OTP_DEV_TEST_PHONES", ("+2348031234567",))

    registered = api_client.post(
        "/api/v1/auth/otp/request/",
        {"phone_number": "08031234567"},
        format="json",
    )
    assert registered.status_code == 200
    assert sent_codes == [("+2348031234567", "123456", 300)]

    verified = api_client.post(
        "/api/v1/auth/otp/verify/",
        {
            "phone_number": "08031234567",
            "request_id": registered.data["request_id"],
            "code": "123456",
        },
        format="json",
    )
    assert verified.status_code == 200
    assert verified.data["setup_token"]

    created = api_client.post(
        "/api/v1/auth/setup-account/",
        {
            "setup_token": verified.data["setup_token"],
            "username": "registered_test_user",
            "password": "StrongPass123!",
            "has_consented": True,
        },
        format="json",
    )
    assert created.status_code == 201
    assert created.data["user"]["phone_number"] == "+2348031234567"

    unregistered = api_client.post(
        "/api/v1/auth/otp/request/",
        {"phone_number": "08031234568"},
        format="json",
    )
    assert unregistered.status_code == 400
    assert (
        unregistered.data["error"]["fields"]["phone_number"][0]
        == "This number is not registered for account setup."
    )


@pytest.mark.django_db
def test_request_otp_invalid_phone_returns_validation_error(api_client):
    response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "12345"}, format="json")
    assert response.status_code == 400
    assert response.data["error"]["code"] == "validation_error"
    assert "Enter a valid Nigerian mobile number" in response.data["error"]["fields"]["phone_number"][0]


@pytest.mark.django_db
def test_otp_request_throttle_allows_ten_distinct_numbers_then_returns_429(
    api_client, sent_codes, monkeypatch
):
    rates = dict(ScopedRateThrottle.THROTTLE_RATES)
    rates["otp_request"] = settings.THROTTLE_OTP_REQUEST
    monkeypatch.setattr(ScopedRateThrottle, "THROTTLE_RATES", rates)

    responses = []
    for number in range(1, 12):
        phone_number = f"+234803123{number:04d}"
        StudentRegistration.objects.create(
            first_name="Amina",
            last_name="Bello",
            matric_number=f"CHDC/{number:04d}",
            phone_number=phone_number,
        )
        responses.append(
            api_client.post(
                "/api/v1/auth/otp/request/",
                {"phone_number": phone_number},
                format="json",
            )
        )

    assert all(response.status_code == 200 for response in responses[:10])
    assert responses[10].status_code == 429
    assert responses[10].data["error"]["code"] == "rate_limited"
    assert len(sent_codes) == 10
