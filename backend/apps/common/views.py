from django.conf import settings
from django.http import FileResponse, Http404
from django.http import JsonResponse
from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(["GET"])
@permission_classes([AllowAny])
@authentication_classes([])
def health(request):
    return Response({"status": "ok"}, status=status.HTTP_200_OK)


def frontend(request):
    index_path = settings.BASE_DIR / "static" / "index.html"
    try:
        index_file = index_path.open("rb")
    except FileNotFoundError as exc:
        raise Http404("Frontend is not available.") from exc
    return FileResponse(index_file, content_type="text/html")


def download_app(request):
    apk_path = settings.BASE_DIR / "media" / "app-release.apk"
    try:
        apk_file = apk_path.open("rb")
    except FileNotFoundError as exc:
        raise Http404("App download is not available.") from exc
    return FileResponse(
        apk_file,
        as_attachment=True,
        filename="app-release.apk",
        content_type="application/vnd.android.package-archive",
    )


def not_found(request, exception=None):
    return JsonResponse({"error": {"code": "not_found", "message": "Not found."}}, status=404)


def server_error(request):
    return JsonResponse({"error": {"code": "server_error", "message": "Something went wrong. Please try again."}}, status=500)
