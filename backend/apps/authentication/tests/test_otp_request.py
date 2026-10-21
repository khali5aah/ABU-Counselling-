import re

import pytest


@pytest.mark.django_db
def test_request_otp_for_registered_number_sends_code_and_stores_verification(api_client, registration, sent_codes):
    response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234567"}, format="json")
    assert response.status_code == 200
    assert set(response.data) == {"request_id", "message", "expires_in", "resend_after"}
    assert response.data["message"] == "If this number is registered and not yet set up, a verification code has been sent by SMS."
    assert len(sent_codes) == 1
    phone, code = sent_codes[0]
    assert phone == "+2348031234567"
    assert re.fullmatch(r"\d{6}", code)
    assert response.data["request_id"]


@pytest.mark.django_db
def test_request_otp_for_unregistered_number_returns_generic_response(api_client, sent_codes):
    response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234568"}, format="json")
    assert response.status_code == 200
    assert response.data["message"] == "If this number is registered and not yet set up, a verification code has been sent by SMS."
    assert sent_codes == []


@pytest.mark.django_db
def test_request_otp_invalid_phone_returns_validation_error(api_client):
    response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "12345"}, format="json")
    assert response.status_code == 400
    assert response.data["error"]["code"] == "validation_error"
    assert "Enter a valid Nigerian mobile number" in response.data["error"]["fields"]["phone_number"][0]
