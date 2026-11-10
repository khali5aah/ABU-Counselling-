import pytest

from apps.common.phone import InvalidPhoneNumber, mask_phone, normalize_ng_phone


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("08031234567", "+2348031234567"),
        ("+2348031234567", "+2348031234567"),
        ("0803-123-4567", "+2348031234567"),
        ("0803 123 4567", "+2348031234567"),
        ("0803.(123)/4567", "+2348031234567"),
        ("(+234)8031234567", "+2348031234567"),
        ("07012345678", "+2347012345678"),
        ("08123456789", "+2348123456789"),
        ("09012345678", "+2349012345678"),
        ("09123456789", "+2349123456789"),
        ("07131234567", "+2347131234567"),
        ("08231234567", "+2348231234567"),
        ("+2346031234567", "+2346031234567"),
    ],
)
def test_phone_normalizes_valid_examples(raw, expected):
    assert normalize_ng_phone(raw) == expected


@pytest.mark.parametrize(
    "raw",
    [
        "",
        "12345",
        "2348031234567",
        "+2348031234",
        "+14155552671",
        "08031234567+",
        "0803abc4567",
        None,
    ],
)
def test_phone_rejects_invalid_examples(raw):
    with pytest.raises(InvalidPhoneNumber):
        normalize_ng_phone(raw)


def test_mask_phone():
    assert mask_phone("+2348031234567") == "+234******4567"
