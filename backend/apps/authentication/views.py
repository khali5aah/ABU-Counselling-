from django.contrib.auth import authenticate
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from apps.authentication.serializers import (
    LoginSerializer,
    LogoutSerializer,
    OtpRequestSerializer,
    OtpVerifySerializer,
    RefreshSerializer,
    SetupAccountSerializer,
    UserSerializer,
)
from apps.authentication.otp.dev_codes import dev_codes_enabled, recent_codes
from apps.authentication.services import issue_tokens, request_otp, setup_account, verify_otp
from apps.common.exceptions import InvalidCredentialsError, InvalidOtpError, SetupTokenInvalidError
from apps.common.phone import InvalidPhoneNumber, normalize_ng_phone
from apps.common.views import not_found


class PublicAPIView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]


@extend_schema(request=OtpRequestSerializer, responses={200: None}, summary="Request OTP")
class OtpRequestView(PublicAPIView):
    throttle_scope = "otp_request"

    def post(self, request):
        serializer = OtpRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = request_otp(serializer.validated_data["phone_number"])
        return Response(payload, status=status.HTTP_200_OK)


@extend_schema(request=OtpVerifySerializer, responses={200: None}, summary="Verify OTP")
class OtpVerifyView(PublicAPIView):
    throttle_scope = "otp_verify"

    def post(self, request):
        serializer = OtpVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = verify_otp(
            serializer.validated_data["phone_number"],
            serializer.validated_data["request_id"],
            serializer.validated_data["code"],
        )
        return Response(payload, status=status.HTTP_200_OK)


@extend_schema(request=SetupAccountSerializer, responses={201: None}, summary="Setup account")
class SetupAccountView(PublicAPIView):
    throttle_scope = "setup"

    def post(self, request):
        serializer = SetupAccountSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = setup_account(
            serializer.validated_data["setup_token"],
            serializer.validated_data["username"],
            serializer.validated_data["password"],
        )
        return Response(issue_tokens(user), status=status.HTTP_201_CREATED)


@extend_schema(request=LoginSerializer, responses={200: None}, summary="Login")
class LoginView(PublicAPIView):
    throttle_scope = "login"

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = authenticate(request, username=serializer.validated_data["username"], password=serializer.validated_data["password"])
        if user is None:
            raise InvalidCredentialsError()
        user.last_login = timezone.now()
        user.save(update_fields=["last_login"])
        return Response(issue_tokens(user), status=status.HTTP_200_OK)


@extend_schema(request=RefreshSerializer, responses={200: None}, summary="Refresh token")
class RefreshView(PublicAPIView):
    def post(self, request):
        serializer = TokenRefreshSerializer(data={"refresh": request.data.get("refresh")})
        try:
            serializer.is_valid(raise_exception=True)
        except TokenError as exc:
            raise InvalidToken(str(exc)) from exc
        return Response(
            {
                "access": serializer.validated_data["access"],
                "refresh": serializer.validated_data.get("refresh"),
            },
            status=status.HTTP_200_OK,
        )


@extend_schema(responses={200: UserSerializer}, summary="Current user")
class MeView(APIView):
    def get(self, request):
        return Response(UserSerializer(request.user).data, status=status.HTTP_200_OK)


@extend_schema(request=LogoutSerializer, responses={204: None}, summary="Logout")
class LogoutView(APIView):
    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response(status=status.HTTP_204_NO_CONTENT)
        try:
            token = RefreshToken(refresh_token)
            if str(token.get("user_id")) == str(request.user.id):
                token.blacklist()
        except TokenError:
            pass
        return Response(status=status.HTTP_204_NO_CONTENT)


@extend_schema(exclude=True)
class DevOtpCodesView(APIView):
    """Development only: recent console OTP codes, so testers can read them from the web app."""

    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = []

    def get(self, request):
        if not dev_codes_enabled():
            return not_found(request)
        phone = None
        raw_phone = request.query_params.get("phone_number")
        if raw_phone:
            try:
                phone = normalize_ng_phone(raw_phone)
            except InvalidPhoneNumber:
                return Response({"codes": []}, status=status.HTTP_200_OK)
        return Response({"codes": recent_codes(phone)}, status=status.HTTP_200_OK)
