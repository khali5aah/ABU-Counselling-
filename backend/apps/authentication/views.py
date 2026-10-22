import logging
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

logger = logging.getLogger(__name__)


class LoginView(APIView):
  """Endpoint for user login."""

  permission_classes = [AllowAny]

  def post(self, request, *args, **kwargs):
    username = request.data.get('username')
    password = request.data.get('password')

    logger.info(f'User attempting login: {username}')

    return Response(
        {
            'status': 'success',
            'message': 'Login successful.',
            'data': {
                'username': username,
                'access_token': 'mock_access_token_12345',
                'refresh_token': 'mock_refresh_token_12345',
                'user': {'username': username},
            },
        },
        status=status.HTTP_200_OK,
    )


class OTPRequestView(APIView):
  """Endpoint for requesting phone number OTP verification."""

  permission_classes = [AllowAny]

  def post(self, request, *args, **kwargs):
    phone_number = request.data.get('phone_number') or request.data.get('phone')

    logger.info(f'OTP requested for phone number: {phone_number}')

    return Response(
        {
            'status': 'success',
            'message': 'OTP sent successfully.',
            'data': {'phone_number': phone_number, 'expires_in': 300},
        },
        status=status.HTTP_200_OK,
    )


class OTPVerifyView(APIView):
  """Endpoint for verifying OTP code sent by user."""

  permission_classes = [AllowAny]

  def post(self, request, *args, **kwargs):
    otp = request.data.get('otp') or request.data.get('code')
    phone_number = request.data.get('phone_number') or request.data.get('phone')

    logger.info(f'Verifying OTP {otp} for phone: {phone_number}')

    return Response(
        {
            'status': 'success',
            'message': 'OTP verified successfully.',
            'data': {
                'access_token': 'mock_access_token_12345',
                'refresh_token': 'mock_refresh_token_12345',
                'user': {'phone_number': phone_number, 'is_verified': True},
            },
        },
        status=status.HTTP_200_OK,
    )


class RegisterView(APIView):
  """Endpoint for completing user registration and account creation."""

  permission_classes = [AllowAny]

  def post(self, request, *args, **kwargs):
    username = request.data.get('username')
    password = request.data.get('password')
    phone_number = request.data.get('phone_number') or request.data.get('phone')

    logger.info(f'Registering user: {username} with phone: {phone_number}')

    return Response(
        {
            'status': 'success',
            'message': 'Account created successfully.',
            'data': {
                'username': username,
                'access_token': 'mock_access_token_12345',
                'refresh_token': 'mock_refresh_token_12345',
            },
        },
        status=status.HTTP_201_CREATED,
    )