import pytest
from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework.throttling import ScopedRateThrottle

User = get_user_model()


@pytest.mark.django_db
def test_login_success_and_me_view(api_client, registration, sent_codes):
    User.objects.create_user(username="amina_b", password="StrongPass123!", registration=registration)

    response = api_client.post("/api/v1/auth/login/", {"username": "AMINA_B", "password": "StrongPass123!"}, format="json")
    assert response.status_code == 200
    assert "access" in response.data and "refresh" in response.data

    me = api_client.get("/api/v1/auth/me/", HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
    assert me.status_code == 200
    assert me.data["username"] == "amina_b"


@pytest.mark.django_db
def test_wrong_password_and_invalid_token_behaviour(api_client, registration):
    User.objects.create_user(username="amina_b", password="StrongPass123!", registration=registration)

    bad = api_client.post("/api/v1/auth/login/", {"username": "amina_b", "password": "WrongPass123!"}, format="json")
    assert bad.status_code == 401
    assert bad.data["error"]["code"] == "invalid_credentials"

    unauth = api_client.get("/api/v1/auth/me/")
    assert unauth.status_code == 401
    assert unauth.data["error"]["code"] == "not_authenticated"

    invalid = api_client.get("/api/v1/auth/me/", HTTP_AUTHORIZATION="Bearer garbage")
    assert invalid.status_code == 401
    assert invalid.data["error"]["code"] == "token_invalid"


@pytest.mark.django_db
def test_login_throttle_allows_ten_attempts(api_client, monkeypatch):
    rates = dict(ScopedRateThrottle.THROTTLE_RATES)
    rates["login"] = settings.THROTTLE_LOGIN
    monkeypatch.setattr(ScopedRateThrottle, "THROTTLE_RATES", rates)

    responses = [
        api_client.post(
            "/api/v1/auth/login/",
            {"username": "amina_b", "password": "WrongPass123!"},
            format="json",
        )
        for _ in range(11)
    ]

    assert all(response.status_code == 401 for response in responses[:10])
    assert responses[10].status_code == 429
    assert responses[10].data["error"]["code"] == "rate_limited"
