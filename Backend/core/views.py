from django.http import JsonResponse
from django.views.decorators.http import require_GET
from rest_framework import permissions, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response

from .models import Appointment, MedicalReport, Medication, SOSLog
from .serializers import (
    AppointmentSerializer,
    LoginSerializer,
    MedicalReportSerializer,
    MedicationSerializer,
    RegisterSerializer,
    SOSLogSerializer,
    UserSerializer,
)


@require_GET
def health(request):
    return JsonResponse({"status": "ok", "service": "backend"})


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def register_view(request):
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    token, _ = Token.objects.get_or_create(user=user)
    return Response(
        {"token": token.key, "user": UserSerializer(user).data},
        status=status.HTTP_201_CREATED,
    )


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def login_view(request):
    serializer = LoginSerializer(data=request.data, context={"request": request})
    serializer.is_valid(raise_exception=True)
    user = serializer.validated_data["user"]
    token, _ = Token.objects.get_or_create(user=user)
    return Response({"token": token.key, "user": UserSerializer(user).data})


@api_view(["POST"])
def logout_view(request):
    if hasattr(request.user, "auth_token"):
        request.user.auth_token.delete()
    return Response({"detail": "Logged out successfully."})


@api_view(["GET", "PATCH"])
def me_view(request):
    if request.method == "GET":
        return Response(UserSerializer(request.user).data)
    serializer = UserSerializer(request.user, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


class OwnerQuerysetMixin:
    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class MedicationViewSet(OwnerQuerysetMixin, viewsets.ModelViewSet):
    queryset = Medication.objects.all().order_by("-created_at")
    serializer_class = MedicationSerializer


class AppointmentViewSet(OwnerQuerysetMixin, viewsets.ModelViewSet):
    queryset = Appointment.objects.all().order_by("appointment_date", "appointment_time")
    serializer_class = AppointmentSerializer


class MedicalReportViewSet(OwnerQuerysetMixin, viewsets.ModelViewSet):
    queryset = MedicalReport.objects.all().order_by("-report_date")
    serializer_class = MedicalReportSerializer


class SOSLogViewSet(OwnerQuerysetMixin, viewsets.ModelViewSet):
    queryset = SOSLog.objects.all().order_by("-triggered_at")
    serializer_class = SOSLogSerializer

    @action(detail=False, methods=["post"])
    def trigger(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user, status="triggered")
        return Response(serializer.data, status=status.HTTP_201_CREATED)
