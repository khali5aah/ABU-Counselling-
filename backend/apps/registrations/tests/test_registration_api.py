import pytest
from django.conf import settings
from django.core.cache import cache
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework.throttling import ScopedRateThrottle

from apps.registrations.codes import hash_signup_code
from apps.registrations.models import StudentRegistration


@pytest.mark.django_db
@pytest.mark.parametrize("phone_number", ["08031234567", "0803 123 4567"])
def test_registration_api_creates_record(phone_number):
    client = APIClient()
    payload = {
        "first_name": "Amina",
        "last_name": "Bello",
        "matric_number": "CHDC/0001",
        "phone_number": phone_number,
        "has_consented": True,
    }

    response = client.post(reverse("registration-create"), payload, format="json")

    assert response.status_code == 201
    assert response.data["matric_number"] == "CHDC/0001"
    assert response.data["phone_number"] == "08031234567"
    assert response.data["first_name"] == "Amina"
    saved = StudentRegistration.objects.get(matric_number="CHDC/0001")
    assert saved.phone_number == "08031234567"
    assert response.data.get("status") is None
    assert StudentRegistration.objects.get(matric_number="CHDC/0001").status == "PENDING"


@pytest.mark.django_db
def test_registration_api_rejects_duplicate_matric_or_phone():
    StudentRegistration.objects.create(
        first_name="Amina",
        last_name="Bello",
        matric_number="CHDC/0001",
        phone_number="08031234567",
    )
    client = APIClient()
    payload = {
        "first_name": "Mary",
        "last_name": "Jane",
        "matric_number": "CHDC/0001",
        "phone_number": "08031234568",
        "has_consented": True,
    }

    response = client.post(reverse("registration-create"), payload, format="json")

    assert response.status_code == 409
    assert response.data["error"]["code"] == "duplicate"
    assert "matric_number" in response.data["error"]["fields"]


@pytest.mark.django_db
def test_registration_api_validates_phone_and_names():
    client = APIClient()
    payload = {
        "first_name": "",
        "last_name": "Bello",
        "matric_number": "CHDC/0001",
        "phone_number": "12345",
    }

    response = client.post(reverse("registration-create"), payload, format="json")

    assert response.status_code == 400
    assert response.data["error"]["code"] == "validation_error"


@pytest.mark.django_db
@pytest.mark.parametrize("phone_number", ["07131234567", "08231234567", "12345678901"])
def test_registration_api_accepts_any_11_digit_prefix(phone_number):
    response = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Amina",
            "last_name": "Bello",
            "matric_number": "CHDC/0001",
            "phone_number": phone_number,
            "has_consented": True,
        },
        format="json",
    )

    assert response.status_code == 201
    assert response.data["phone_number"] == phone_number
    assert StudentRegistration.objects.filter(phone_number=phone_number).exists()


@pytest.mark.parametrize(
    "phone_number",
    ["+2348031234567", "2348031234567", "0803123456", "080312345678"],
)
def test_registration_api_rejects_non_local_or_wrong_length_phone(phone_number):
    response = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Amina",
            "last_name": "Bello",
            "matric_number": "CHDC/0001",
            "phone_number": phone_number,
            "has_consented": True,
        },
        format="json",
    )

    assert response.status_code == 400
    assert "phone_number" in response.data["error"]["fields"]
    assert response.data["error"]["fields"]["phone_number"] == [
        "Phone number must be exactly 11 digits."
    ]


@pytest.mark.django_db
@pytest.mark.parametrize("matric_number", ["CHDC/001", "CHDC/00011"])
def test_registration_api_requires_exactly_nine_matric_characters(matric_number):
    response = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Amina",
            "last_name": "Bello",
            "matric_number": matric_number,
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )

    assert response.status_code == 400
    assert "matric_number" in response.data["error"]["fields"]
    assert response.data["error"]["fields"]["matric_number"] == [
        "Matric number must be exactly 9 characters."
    ]
    assert not StudentRegistration.objects.exists()


@pytest.mark.django_db
def test_registration_api_accepts_any_nine_matric_characters():
    response = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Amina",
            "last_name": "Bello",
            "matric_number": "!@#$%^&*(",
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )

    assert response.status_code == 201
    assert response.data["matric_number"] == "!@#$%^&*("


@pytest.mark.django_db
def test_registration_api_checks_matric_length_before_uppercasing():
    response = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Amina",
            "last_name": "Bello",
            "matric_number": "ß12345678",
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )

    assert response.status_code == 201
    assert response.data["matric_number"] == "SS12345678"


@pytest.mark.django_db
def test_registration_api_trims_matric_number_whitespace():
    response = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Amina",
            "last_name": "Bello",
            "matric_number": " CHDC/0001 ",
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )

    assert response.status_code == 201
    assert response.data["matric_number"] == "CHDC/0001"


@pytest.mark.django_db
def test_registration_api_requires_consent():
    client = APIClient()
    payload = {
        "first_name": "Amina",
        "last_name": "Bello",
        "matric_number": "CHDC/0001",
        "phone_number": "08031234567",
        "has_consented": False,
    }

    response = client.post(reverse("registration-create"), payload, format="json")

    assert response.status_code == 400
    assert response.data["error"]["code"] == "validation_error"
    assert not StudentRegistration.objects.exists()


@pytest.mark.django_db
def test_registration_throttle_allows_ten_requests_then_returns_429(monkeypatch):
    rates = dict(ScopedRateThrottle.THROTTLE_RATES)
    rates["registration"] = settings.THROTTLE_REGISTRATION
    monkeypatch.setattr(ScopedRateThrottle, "THROTTLE_RATES", rates)

    client = APIClient()
    payload = {
        "first_name": "Amina",
        "last_name": "Bello",
        "matric_number": "CHDC/0001",
        "phone_number": "08031234567",
        "has_consented": True,
    }
    responses = [
        client.post(reverse("registration-create"), payload, format="json")
        for _ in range(11)
    ]

    assert all(response.status_code == 201 for response in responses[:10])
    assert responses[10].status_code == 429
    assert responses[10].data["error"]["code"] == "rate_limited"


@pytest.mark.django_db
def test_development_signup_code_creates_mobile_account_once(monkeypatch):
    monkeypatch.setattr(settings, "DEBUG", True)
    monkeypatch.setattr(settings, "OTP_PROVIDER", "console")
    client = APIClient()
    registration = client.post(
        reverse("registration-create"),
        {
            "first_name": "Amina",
            "last_name": "Bello",
            "matric_number": "CHDC/0002",
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )
    assert registration.status_code == 201
    signup_code = registration.data["signup_code"]
    record = StudentRegistration.objects.get(matric_number="CHDC/0002")
    assert signup_code.isdigit() and len(signup_code) == 6
    assert record.signup_code_hash == hash_signup_code(record.id, signup_code)
    assert record.signup_code_expires_at is not None
    remaining = (record.signup_code_expires_at - timezone.now()).total_seconds()
    assert 890 < remaining <= 900

    request = client.post(
        "/api/v1/auth/otp/request/",
        {"phone_number": "08031234567"},
        format="json",
    )
    assert request.status_code == 200
    assert request.data["is_registration_code"] is True
    assert request.data["expires_in"] <= 15 * 60

    verified = client.post(
        "/api/v1/auth/otp/verify/",
        {
            "phone_number": "08031234567",
            "request_id": request.data["request_id"],
            "code": signup_code,
        },
        format="json",
    )
    assert verified.status_code == 200
    created = client.post(
        "/api/v1/auth/setup-account/",
        {
            "setup_token": verified.data["setup_token"],
            "username": "amina_bello",
            "password": "StrongPass123!",
            "has_consented": True,
        },
        format="json",
    )
    assert created.status_code == 201
    record.refresh_from_db()
    assert record.signup_code_used_at is not None
    assert record.status == StudentRegistration.Status.COMPLETED

    cache.clear()
    reused = client.post(
        "/api/v1/auth/otp/request/",
        {"phone_number": "08031234567"},
        format="json",
    )
    assert reused.status_code == 400


@pytest.mark.django_db
def test_registration_can_be_reused_only_before_completion():
    existing = StudentRegistration.objects.create(
        first_name="Amina",
        last_name="Bello",
        matric_number="CHDC/0001",
        phone_number="08031234567",
        status=StudentRegistration.Status.PENDING,
    )
    response = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Mary",
            "last_name": "Jane",
            "matric_number": "CHDC/0002",
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )
    assert response.status_code == 201
    existing.refresh_from_db()
    assert StudentRegistration.objects.count() == 1
    assert existing.first_name == "Mary"
    assert existing.matric_number == "CHDC/0002"
    assert existing.phone_number == "08031234567"
    assert existing.status == StudentRegistration.Status.PENDING

    existing.status = StudentRegistration.Status.EXPIRED
    existing.save(update_fields=["status"])
    repeated = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Mary",
            "last_name": "Jane",
            "matric_number": "CHDC/0002",
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )
    assert repeated.status_code == 201
    existing.refresh_from_db()
    assert existing.status == StudentRegistration.Status.PENDING

    existing.status = StudentRegistration.Status.COMPLETED
    existing.save(update_fields=["status"])
    blocked = APIClient().post(
        reverse("registration-create"),
        {
            "first_name": "Mary",
            "last_name": "Jane",
            "matric_number": "CHDC/0002",
            "phone_number": "08031234567",
            "has_consented": True,
        },
        format="json",
    )
    assert blocked.status_code == 409
    assert blocked.data["error"]["fields"]["phone_number"]
