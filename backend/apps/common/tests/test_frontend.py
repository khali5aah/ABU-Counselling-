from django.test import Client, override_settings
from django.urls import reverse


def test_frontend_serves_built_index(tmp_path):
    static_path = tmp_path / "static"
    static_path.mkdir()
    html = b"<!doctype html><title>CHDC E-Counselling</title>"
    (static_path / "index.html").write_bytes(html)

    with override_settings(BASE_DIR=tmp_path):
        response = Client().get(reverse("frontend"))

    assert response.status_code == 200
    assert response["Content-Type"] == "text/html"
    assert b"".join(response.streaming_content) == html


def test_frontend_returns_404_when_build_is_missing(tmp_path):
    with override_settings(BASE_DIR=tmp_path):
        response = Client().get(reverse("frontend"))

    assert response.status_code == 404
