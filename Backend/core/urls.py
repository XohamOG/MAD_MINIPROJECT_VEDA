from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AppointmentViewSet,
    MedicalReportViewSet,
    MedicationViewSet,
    SOSLogViewSet,
    health,
    login_view,
    logout_view,
    me_view,
    register_view,
)

router = DefaultRouter()
router.register("medications", MedicationViewSet, basename="medication")
router.register("appointments", AppointmentViewSet, basename="appointment")
router.register("reports", MedicalReportViewSet, basename="report")
router.register("sos-logs", SOSLogViewSet, basename="sos-log")

urlpatterns = [
    path("health/", health, name="health"),
    path("auth/register/", register_view, name="register"),
    path("auth/login/", login_view, name="login"),
    path("auth/logout/", logout_view, name="logout"),
    path("auth/me/", me_view, name="me"),
    path("", include(router.urls)),
]
