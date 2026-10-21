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


def not_found(request, exception=None):
    return JsonResponse({"error": {"code": "not_found", "message": "Not found."}}, status=404)


def server_error(request):
    return JsonResponse({"error": {"code": "server_error", "message": "Something went wrong. Please try again."}}, status=500)
