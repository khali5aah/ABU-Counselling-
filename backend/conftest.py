import pytest
from django.core import cache
from django.core.management import call_command
import rest_framework.throttling


@pytest.fixture(scope="session")
def django_db_setup(django_db_setup, django_db_blocker):
    with django_db_blocker.unblock():
        call_command("createcachetable")


@pytest.fixture(autouse=True)
def reset_cache_and_throttles(db, monkeypatch):
    cache.cache.clear()
    monkeypatch.setattr(
        rest_framework.throttling.ScopedRateThrottle,
        "THROTTLE_RATES",
        {
            "registration": "10000/minute",
            "otp_request": "10000/minute",
            "otp_verify": "10000/minute",
            "setup": "10000/minute",
            "login": "10000/minute",
        },
    )
