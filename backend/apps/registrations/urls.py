from django.urls import path

from apps.registrations.views import RegistrationCreateView

urlpatterns = [
    path("", RegistrationCreateView.as_view(), name="registration-create"),
]
