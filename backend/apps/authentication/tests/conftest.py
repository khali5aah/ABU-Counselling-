import pytest
from django.core import cache
from django.core.management import call_command
from rest_framework.test import APIClient

from apps.authentication import services as services_module
from apps.registrations.models import StudentRegistration


@pytest.fixture(scope="session")
def django_db_setup(django_db_setup, django_db_blocker):
    with django_db_blocker.unblock():
        call_command("createcachetable")


@pytest.fixture(autouse=True)
def reset_cache_and_throttles(db, monkeypatch):
    cache.cache.clear()
    monkeypatch.setattr(
        "rest_framework.throttling.ScopedRateThrottle.THROTTLE_RATES",
        {
            "registration": "10000/minute",
            "otp_request": "10000/minute",
            "otp_verify": "10000/minute",
            "setup": "10000/minute",
            "login": "10000/minute",
        },
        raising=False,
    )


@pytest.fixture
def registration(db):
    return StudentRegistration.objects.create(
        first_name="Amina",
        last_name="Bello",
        matric_number="CHDC/0001",
        phone_number="+2348031234567",
    )


@pytest.fixture
def sent_codes(monkeypatch):
    calls = []

    class FakeProvider:
        def send_code(self, phone_e164, code):
            calls.append((phone_e164, code))

    monkeypatch.setattr(services_module, "get_otp_provider", lambda: FakeProvider())
    return calls


@pytest.fixture
def api_client():
    return APIClient()


def verified_setup_token(client, sent_codes, phone_number="08031234567", username="amina_b"):
    response = client.post("/api/v1/auth/otp/request/", {"phone_number": phone_number}, format="json")
    assert response.status_code == 200
    request_id = response.data["request_id"]
    assert sent_codes
    code = sent_codes[-1][1]
    verify = client.post(
        "/api/v1/auth/otp/verify/",
        {"phone_number": phone_number, "request_id": request_id, "code": code},
        format="json",
    )
    assert verify.status_code == 200
    token = verify.data["setup_token"]
    assert token
    return token
