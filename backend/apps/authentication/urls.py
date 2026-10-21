from django.urls import path

from apps.authentication.views import LoginView, LogoutView, MeView, OtpRequestView, OtpVerifyView, RefreshView, SetupAccountView

urlpatterns = [
    path("otp/request/", OtpRequestView.as_view(), name="otp-request"),
    path("otp/verify/", OtpVerifyView.as_view(), name="otp-verify"),
    path("setup-account/", SetupAccountView.as_view(), name="setup-account"),
    path("login/", LoginView.as_view(), name="login"),
    path("refresh/", RefreshView.as_view(), name="refresh"),
    path("me/", MeView.as_view(), name="me"),
    path("logout/", LogoutView.as_view(), name="logout"),
]
