from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AppointmentViewSet,
    DoctorViewSet,
    MedicalReportViewSet,
    MedicationViewSet,
    SOSLogViewSet,
    doctor_appointments_view,
    doctor_day_status_view,
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
router.register("doctors", DoctorViewSet, basename="doctor")

urlpatterns = [
    path("health/", health, name="health"),
    path("auth/register/", register_view, name="register"),
    path("auth/login/", login_view, name="login"),
    path("auth/logout/", logout_view, name="logout"),
    path("auth/me/", me_view, name="me"),
    path("doctor/day-status/", doctor_day_status_view, name="doctor-day-status"),
    path("doctor/appointments/", doctor_appointments_view, name="doctor-appointments"),
    path("", include(router.urls)),
]
