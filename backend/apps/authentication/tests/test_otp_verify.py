import pytest

from apps.authentication import services
from apps.authentication.models import PhoneVerification


@pytest.mark.django_db
def test_verify_otp_allows_ten_incorrect_attempts_before_lockout(
    api_client, registration, sent_codes, monkeypatch
):
    monkeypatch.setattr(services.settings, "OTP_MAX_ATTEMPTS", 10)
    request_response = api_client.post(
        "/api/v1/auth/otp/request/",
        {"phone_number": "08031234567"},
        format="json",
    )
    assert request_response.status_code == 200
    request_id = request_response.data["request_id"]
    wrong_code = "000000" if sent_codes[-1][1] != "000000" else "000001"

    responses = [
        api_client.post(
            "/api/v1/auth/otp/verify/",
            {
                "phone_number": "08031234567",
                "request_id": request_id,
                "code": wrong_code,
            },
            format="json",
        )
        for _ in range(10)
    ]

    assert all(response.data["error"]["code"] == "invalid_otp" for response in responses[:9])
    assert responses[0].data["error"]["attempts_remaining"] == 9
    assert responses[8].data["error"]["attempts_remaining"] == 1
    assert responses[9].data["error"]["code"] == "otp_attempts_exceeded"
    verification = PhoneVerification.objects.get(id=request_id)
    assert verification.attempts == 10
    assert verification.max_attempts == 10


@pytest.mark.django_db
def test_verify_otp_with_correct_code_returns_setup_token(api_client, registration, sent_codes):
    request_response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234567"}, format="json")
    request_id = request_response.data["request_id"]
    code = sent_codes[-1][1]

    response = api_client.post(
        "/api/v1/auth/otp/verify/",
        {"phone_number": "08031234567", "request_id": request_id, "code": code},
        format="json",
    )

    assert response.status_code == 200
    assert "setup_token" in response.data
    assert response.data["expires_in"] == 900
    assert len(response.data["setup_token"]) >= 40


@pytest.mark.django_db
def test_verify_otp_wrong_code_tracks_attempts_and_expires(api_client, registration, sent_codes):
    request_response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234567"}, format="json")
    request_id = request_response.data["request_id"]

    wrong = api_client.post(
        "/api/v1/auth/otp/verify/",
        {"phone_number": "08031234567", "request_id": request_id, "code": "000000"},
        format="json",
    )
    assert wrong.status_code == 400
    assert wrong.data["error"]["code"] == "invalid_otp"
    assert "attempts_remaining" in wrong.data["error"]


@pytest.mark.django_db
def test_verify_otp_with_bad_format_returns_validation_error(api_client, registration):
    response = api_client.post(
        "/api/v1/auth/otp/verify/",
        {"phone_number": "08031234567", "request_id": "not-a-uuid", "code": "12ab56"},
        format="json",
    )
    assert response.status_code == 400
    assert response.data["error"]["code"] == "validation_error"
    assert "code" in response.data["error"]["fields"]
