from django.test import Client, override_settings
from django.urls import reverse


def test_download_app_returns_apk_as_attachment(tmp_path):
    media_path = tmp_path / "media"
    media_path.mkdir()
    apk_contents = b"apk test contents"
    (media_path / "app-release.apk").write_bytes(apk_contents)

    with override_settings(BASE_DIR=tmp_path):
        response = Client().get(reverse("download-app"))

    assert response.status_code == 200
    assert response["Content-Type"] == "application/vnd.android.package-archive"
    assert response["Content-Disposition"] == 'attachment; filename="app-release.apk"'
    assert b"".join(response.streaming_content) == apk_contents


def test_download_app_returns_404_when_apk_is_missing(tmp_path):
    with override_settings(BASE_DIR=tmp_path):
        response = Client().get(reverse("download-app"))

    assert response.status_code == 404
