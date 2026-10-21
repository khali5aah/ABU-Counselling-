import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from apps.registrations.models import StudentRegistration


@pytest.mark.django_db
def test_registration_api_creates_record():
    client = APIClient()
    payload = {
        "first_name": "Amina",
        "last_name": "Bello",
        "matric_number": "CHDC/0001",
        "phone_number": "08031234567",
    }

    response = client.post(reverse("registration-create"), payload, format="json")

    assert response.status_code == 201
    assert response.data["matric_number"] == "CHDC/0001"
    assert response.data["phone_number"] == "+2348031234567"
    assert response.data["first_name"] == "Amina"
    assert StudentRegistration.objects.filter(matric_number="CHDC/0001").exists()


@pytest.mark.django_db
def test_registration_api_rejects_duplicate_matric_or_phone():
    StudentRegistration.objects.create(
        first_name="Amina",
        last_name="Bello",
        matric_number="CHDC/0001",
        phone_number="+2348031234567",
    )
    client = APIClient()
    payload = {
        "first_name": "Mary",
        "last_name": "Jane",
        "matric_number": "CHDC/0001",
        "phone_number": "08031234568",
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
