import pytest

from apps.authentication.otp.providers import ConsoleOtpProvider

URL = "/api/v1/dev/otp-codes/"


@pytest.fixture
def dev_mode(settings):
    settings.DEBUG = True
    settings.OTP_PROVIDER = "console"


@pytest.mark.django_db
def test_lists_console_codes_newest_first_and_filters_by_phone(api_client, dev_mode):
    provider = ConsoleOtpProvider()
    provider.send_code("+2348031234567", "111111")
    provider.send_code("+2348123456789", "222222")
    provider.send_code("+2348031234567", "333333")

    response = api_client.get(URL)
    assert response.status_code == 200
    assert [c["code"] for c in response.data["codes"]] == ["333333", "222222", "111111"]

    filtered = api_client.get(URL, {"phone_number": "0803 123 4567"})
    assert [c["code"] for c in filtered.data["codes"]] == ["333333", "111111"]
    assert filtered.data["codes"][0]["phone_number"] == "+2348031234567"


@pytest.mark.django_db
def test_otp_request_makes_code_visible(api_client, registration, dev_mode):
    api_client.post("/api/v1/auth/otp/request/", {"phone_number": "08031234567"}, format="json")

    codes = api_client.get(URL, {"phone_number": "08031234567"}).data["codes"]
    assert len(codes) == 1
    assert len(codes[0]["code"]) == 6


@pytest.mark.django_db
def test_invalid_phone_returns_no_codes(api_client, dev_mode):
    ConsoleOtpProvider().send_code("+2348031234567", "111111")
    assert api_client.get(URL, {"phone_number": "12345"}).data == {"codes": []}


@pytest.mark.django_db
def test_hidden_when_not_in_dev_mode(api_client, settings):
    settings.DEBUG = True
    settings.OTP_PROVIDER = "termii"
    assert api_client.get(URL).status_code == 404

    settings.OTP_PROVIDER = "console"
    settings.DEBUG = False
    assert api_client.get(URL).status_code == 404
