import pytest
from django.contrib.auth import get_user_model

from apps.registrations.models import StudentRegistration

User = get_user_model()


@pytest.mark.django_db
def test_setup_account_success_and_token_reuse(api_client, registration, sent_codes):
    request_response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234567"}, format="json")
    request_id = request_response.data["request_id"]
    code = sent_codes[-1][1]
    verify = api_client.post(
        "/api/v1/auth/otp/verify/",
        {"phone_number": "08031234567", "request_id": request_id, "code": code},
        format="json",
    )
    token = verify.data["setup_token"]

    response = api_client.post(
        "/api/v1/auth/setup-account/",
        {"setup_token": token, "username": "Amina_B", "password": "StrongPass123!"},
        format="json",
    )

    assert response.status_code == 201
    assert response.data["user"]["username"] == "amina_b"
    assert response.data["user"]["phone_number"] == "+2348031234567"
    assert "first_name" not in response.data["user"]
    assert "last_name" not in response.data["user"]
    assert User.objects.filter(registration=registration).exists()

    reused = api_client.post(
        "/api/v1/auth/setup-account/",
        {"setup_token": token, "username": "another_user", "password": "StrongPass123!"},
        format="json",
    )
    assert reused.status_code == 400
    assert reused.data["error"]["code"] == "setup_token_invalid"


@pytest.mark.django_db
def test_setup_account_rejects_duplicate_username_and_weak_password(api_client, registration, sent_codes):
    request_response = api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234567"}, format="json")
    verify = api_client.post(
        "/api/v1/auth/otp/verify/",
        {"phone_number": "08031234567", "request_id": request_response.data["request_id"], "code": sent_codes[-1][1]},
        format="json",
    )
    token = verify.data["setup_token"]
    User.objects.create_user(username="taken_user", password="StrongPass123!")

    bad_password = api_client.post(
        "/api/v1/auth/setup-account/",
        {"setup_token": token, "username": "new_user", "password": "12345678"},
        format="json",
    )
    assert bad_password.status_code == 400
    assert bad_password.data["error"]["code"] == "validation_error"

    duplicate_user = api_client.post(
        "/api/v1/auth/setup-account/",
        {"setup_token": token, "username": "Taken_User", "password": "StrongPass123!"},
        format="json",
    )
    assert duplicate_user.status_code == 409
    assert duplicate_user.data["error"]["code"] == "duplicate"
