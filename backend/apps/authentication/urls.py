from django.urls import path
from .views import LoginView, OTPRequestView, OTPVerifyView, RegisterView

urlpatterns = [
    # OTP Endpoints
    path('otp/request/', OTPRequestView.as_view(), name='otp_request'),
    path('otp/verify/', OTPVerifyView.as_view(), name='otp_verify'),
    
    # Account Registration Endpoints
    path('setup-account/', RegisterView.as_view(), name='setup_account'),
    path('register/', RegisterView.as_view(), name='register'),
    path('signup/', RegisterView.as_view(), name='signup'),
    
    # Login / Token Endpoints
    path('login/', LoginView.as_view(), name='login'),
    path('token/', LoginView.as_view(), name='token'),
    path('token/login/', LoginView.as_view(), name='token_login'),
    path('auth/login/', LoginView.as_view(), name='auth_login'),
]