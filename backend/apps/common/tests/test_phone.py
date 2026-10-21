import pytest

from apps.common.phone import InvalidPhoneNumber, mask_phone, normalize_ng_phone


@pytest.mark.parametrize(
    "raw",
    [
        "08031234567",
        "+2348031234567",
        "2348031234567",
        "0803-123-4567",
        "0803 123 4567",
        "08031234567",
        "(+234)8031234567",
    ],
)
def test_phone_normalizes_valid_examples(raw):
    assert normalize_ng_phone(raw) == "+2348031234567"


@pytest.mark.parametrize("raw", ["", "12345", "+2348031234", "+2346031234567", "08231234567", "+14155552671", None])
def test_phone_rejects_invalid_examples(raw):
    with pytest.raises(InvalidPhoneNumber):
        normalize_ng_phone(raw)


def test_mask_phone():
    assert mask_phone("+2348031234567") == "+234******4567"
