import json

from rest_framework.exceptions import NotAuthenticated, Throttled, ValidationError as DRFValidationError
from rest_framework.test import APIRequestFactory

from apps.common.exceptions import DuplicateError, api_exception_handler
from apps.common.views import health, not_found


factory = APIRequestFactory()


def test_validation_error_envelope():
    request = factory.post("/api/v1/test/")
    exc = DRFValidationError({"name": ["This field is required."]})
    response = api_exception_handler(exc, {"request": request})

    assert response.status_code == 400
    assert response.data == {
        "error": {
            "code": "validation_error",
            "message": "Please correct the highlighted fields.",
            "fields": {"name": ["This field is required."]},
        }
    }


def test_throttled_error_envelope():
    request = factory.get("/api/v1/test/")
    exc = Throttled(wait=2.2)
    response = api_exception_handler(exc, {"request": request})

    assert response.status_code == 429
    assert response.data["error"]["code"] == "rate_limited"
    assert response.data["error"]["retry_after"] == 3
    assert response["Retry-After"] == "3"


def test_not_authenticated_error_envelope():
    request = factory.get("/api/v1/test/")
    exc = NotAuthenticated()
    response = api_exception_handler(exc, {"request": request})

    assert response.status_code == 401
    assert response.data["error"]["code"] == "not_authenticated"


def test_api_error_envelope():
    request = factory.post("/api/v1/test/")
    exc = DuplicateError()
    response = api_exception_handler(exc, {"request": request})

    assert response.status_code == 409
    assert response.data == {
        "error": {
            "code": "duplicate",
            "message": "Some details are already registered.",
        }
    }


def test_unhandled_exception_error_envelope():
    request = factory.get("/api/v1/test/")
    response = api_exception_handler(ZeroDivisionError("bad"), {"request": request})

    assert response.status_code == 500
    assert response.data["error"]["code"] == "server_error"


def test_health_view_returns_ok_payload():
    request = factory.get("/api/v1/health/")
    response = health(request)

    assert response.status_code == 200
    assert response.data == {"status": "ok"}


def test_not_found_view_returns_error_payload():
    request = factory.get("/api/v1/does-not-exist/")
    response = not_found(request)

    assert response.status_code == 404
    payload = json.loads(response.content.decode("utf-8"))
    assert payload == {"error": {"code": "not_found", "message": "Not found."}}
