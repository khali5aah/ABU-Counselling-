import logging

from drf_spectacular.utils import extend_schema
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.common.phone import mask_phone
from apps.registrations.serializers import RegistrationCreateSerializer, RegistrationResponseSerializer

logger = logging.getLogger("chdc.registrations")


class RegistrationCreateView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "registration"

    @extend_schema(
        request=RegistrationCreateSerializer,
        responses={201: RegistrationResponseSerializer},
        summary="Register a student (web)",
    )
    def post(self, request):
        serializer = RegistrationCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        registration = serializer.save()
        logger.info(
            "registration created matric=%s phone=%s",
            registration.matric_number,
            mask_phone(registration.phone_number),
        )
        return Response(RegistrationResponseSerializer(registration).data, status=201)
