from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.common import views

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/health/", views.health),
    path("api/v1/registrations/", include("apps.registrations.urls")),
    path("api/v1/auth/", include("apps.authentication.urls")),
    path("api/v1/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/v1/docs/", SpectacularSwaggerView.as_view(url_name="schema")),
]

handler404 = "apps.common.views.not_found"
handler500 = "apps.common.views.server_error"
