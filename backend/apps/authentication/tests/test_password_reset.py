from datetime import timedelta

import pytest
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.utils import timezone

from apps.authentication.models import PasswordReset
from apps.authentication.services import hash_password_reset_code
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()


@pytest.mark.django_db
def test_password_reset_updates_password_once(api_client, registration, sent_codes):
    user = User.objects.create_user(
        username="amina_b", password="OldStrong123!", registration=registration
    )
    old_refresh = str(RefreshToken.for_user(user))
    requested = api_client.post(
        "/api/v1/auth/forgot-password/",
        {"phone_number": "08031234567"},
        format="json",
    )
    assert requested.status_code == 200
    assert requested.data["expires_in"] == 900
    assert "If an account exists" in requested.data["message"]
    phone, code, lifetime = sent_codes[-1]
    assert phone == registration.phone_number
    assert lifetime == 900

    reset = PasswordReset.objects.get(id=requested.data["request_id"])
    assert reset.otp_code == hash_password_reset_code(reset.id, code)
    assert reset.otp_code != code

    weak_password = api_client.post(
        "/api/v1/auth/reset-password/",
        {
            "phone_number": registration.phone_number,
            "request_id": requested.data["request_id"],
            "otp_code": code,
            "new_password": "12345678",
        },
        format="json",
    )
    assert weak_password.status_code == 400
    assert weak_password.data["error"]["code"] == "validation_error"
    reset.refresh_from_db()
    assert not reset.is_used

    confirmed = api_client.post(
        "/api/v1/auth/reset-password/",
        {
            "phone_number": registration.phone_number,
            "request_id": requested.data["request_id"],
            "otp_code": code,
            "new_password": "NewStrongPass123!",
        },
        format="json",
    )
    assert confirmed.status_code == 200
    user.refresh_from_db()
    assert user.check_password("NewStrongPass123!")
    rejected_refresh = api_client.post(
        "/api/v1/auth/refresh/",
        {"refresh": old_refresh},
        format="json",
    )
    assert rejected_refresh.status_code == 401
    assert rejected_refresh.data["error"]["code"] == "token_invalid"
    reset.refresh_from_db()
    assert reset.is_used

    reused = api_client.post(
        "/api/v1/auth/reset-password/",
        {
            "phone_number": registration.phone_number,
            "request_id": requested.data["request_id"],
            "otp_code": code,
            "new_password": "AnotherStrong123!",
        },
        format="json",
    )
    assert reused.status_code == 400
    assert reused.data["error"]["code"] == "invalid_otp"


@pytest.mark.django_db
def test_password_reset_request_does_not_disclose_unknown_phone(api_client, sent_codes):
    response = api_client.post(
        "/api/v1/auth/forgot-password/",
        {"phone_number": "08031234567"},
        format="json",
    )
    assert response.status_code == 200
    assert response.data["message"] == (
        "If an account exists for this phone number, a password reset code has been sent by SMS."
    )
    assert sent_codes == []
    assert not PasswordReset.objects.exists()


@pytest.mark.django_db
def test_password_reset_expires_and_locks_after_wrong_attempt_limit(
    api_client, registration, sent_codes
):
    User.objects.create_user(
        username="amina_b", password="OldStrong123!", registration=registration
    )
    requested = api_client.post(
        "/api/v1/auth/forgot-password/",
        {"phone_number": registration.phone_number},
        format="json",
    )
    reset = PasswordReset.objects.get(id=requested.data["request_id"])
    code = sent_codes[-1][1]
    wrong_code = "000000" if code != "000000" else "000001"

    responses = []
    for _ in range(10):
        response = api_client.post(
            "/api/v1/auth/reset-password/",
            {
                "phone_number": registration.phone_number,
                "request_id": requested.data["request_id"],
                "otp_code": wrong_code,
                "new_password": "NewStrongPass123!",
            },
            format="json",
        )
        assert response.status_code == 400
        responses.append(response)
    assert all(
        response.data["error"]["code"] == "invalid_otp"
        for response in responses[:9]
    )
    assert response.data["error"]["code"] == "otp_attempts_exceeded"
    reset.refresh_from_db()
    assert reset.is_used

    cache.clear()
    requested = api_client.post(
        "/api/v1/auth/forgot-password/",
        {"phone_number": registration.phone_number},
        format="json",
    )
    reset = PasswordReset.objects.get(id=requested.data["request_id"])
    reset.expires_at = timezone.now() - timedelta(seconds=1)
    reset.save(update_fields=["expires_at"])
    expired = api_client.post(
        "/api/v1/auth/reset-password/",
        {
            "phone_number": registration.phone_number,
            "request_id": requested.data["request_id"],
            "otp_code": sent_codes[-1][1],
            "new_password": "NewStrongPass123!",
        },
        format="json",
    )
    assert expired.status_code == 400
    assert expired.data["error"]["code"] == "otp_expired"
