from django.db import transaction
from django.http import JsonResponse
from django.utils.dateparse import parse_date
from django.views.decorators.http import require_GET
import re
from rest_framework import permissions, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response

from .models import Appointment, DoctorDayAvailability, MedicalReport, Medication, SOSLog, User
from .serializers import (
    AppointmentSerializer,
    DoctorDayAvailabilitySerializer,
    DoctorListSerializer,
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


class AppointmentViewSet(viewsets.ModelViewSet):
    queryset = Appointment.objects.select_related("user", "doctor").all().order_by("appointment_date", "appointment_time")
    serializer_class = AppointmentSerializer

    def get_queryset(self):
        if self.request.user.role == "doctor":
            return self.queryset.filter(doctor=self.request.user)
        return self.queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        if user.role != "patient":
            raise PermissionDenied("Only patients can book appointments.")

        doctor = serializer.validated_data["doctor"]
        appointment_date = serializer.validated_data["appointment_date"]

        with transaction.atomic():
            availability, _ = DoctorDayAvailability.objects.select_for_update().get_or_create(
                doctor=doctor,
                date=appointment_date,
                defaults={"seat_limit": doctor.daily_seat_limit},
            )

            booked_count = Appointment.objects.select_for_update().filter(
                doctor=doctor,
                appointment_date=appointment_date,
                status="scheduled",
            ).count()

            if availability.doctor_marked_full or availability.is_full:
                raise ValidationError({"detail": "Doctor is marked full for this day. Please choose another date."})

            if booked_count >= availability.seat_limit:
                availability.is_full = True
                availability.save(update_fields=["is_full", "updated_at"])
                raise ValidationError({"detail": "No seats available for this day. Please choose another date."})

            serializer.save(user=user, status="scheduled")

            if booked_count + 1 >= availability.seat_limit and not availability.is_full:
                availability.is_full = True
                availability.save(update_fields=["is_full", "updated_at"])

    def perform_destroy(self, instance):
        doctor = instance.doctor
        appointment_date = instance.appointment_date
        was_scheduled = instance.status == "scheduled"
        super().perform_destroy(instance)

        if doctor is None or not was_scheduled:
            return

        with transaction.atomic():
            availability = DoctorDayAvailability.objects.select_for_update().filter(
                doctor=doctor,
                date=appointment_date,
            ).first()
            if availability is None or availability.doctor_marked_full:
                return

            booked_count = Appointment.objects.filter(
                doctor=doctor,
                appointment_date=appointment_date,
                status="scheduled",
            ).count()
            should_be_full = booked_count >= availability.seat_limit
            if availability.is_full != should_be_full:
                availability.is_full = should_be_full
                availability.save(update_fields=["is_full", "updated_at"])


class DoctorViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = DoctorListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = User.objects.filter(role="doctor", is_active=True).order_by("full_name")
        area = self.request.query_params.get("area", "").strip()
        category = self.request.query_params.get("category", "").strip()
        city = self.request.query_params.get("city", "").strip()

        if area:
            queryset = queryset.filter(doctor_area__iexact=area)
        if category:
            queryset = queryset.filter(doctor_category__iexact=category)
        if city:
            queryset = queryset.filter(doctor_city__iexact=city)
        return queryset

    def get_serializer_context(self):
        context = super().get_serializer_context()
        date_text = self.request.query_params.get("date", "").strip()
        context["selected_date"] = parse_date(date_text) if date_text else None
        return context


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
        sos_log = serializer.save(user=request.user, status="triggered")

        raw_contacts = (request.user.emergency_contact_phone or "").strip()
        phones = [
            item.strip()
            for item in re.split(r"[;,]", raw_contacts)
            if item.strip()
        ]
        if phones:
            contacts = User.objects.filter(phone__in=phones).exclude(id=request.user.id)
            for contact in contacts:
                SOSLog.objects.create(
                    user=contact,
                    latitude=sos_log.latitude,
                    longitude=sos_log.longitude,
                    message=(
                        f"Emergency alert from {request.user.full_name}: "
                        f"{(sos_log.message or '')[:180]}"
                    )[:255],
                    status="triggered",
                )

        return Response(self.get_serializer(sos_log).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "POST"])
def doctor_day_status_view(request):
    if request.user.role != "doctor":
        return Response({"detail": "Only doctors can access this endpoint."}, status=status.HTTP_403_FORBIDDEN)

    date_text = (
        request.query_params.get("date", "").strip()
        if request.method == "GET"
        else str(request.data.get("date", "")).strip()
    )
    selected_date = parse_date(date_text)
    if selected_date is None:
        return Response({"detail": "A valid date is required (YYYY-MM-DD)."}, status=status.HTTP_400_BAD_REQUEST)

    availability, _ = DoctorDayAvailability.objects.get_or_create(
        doctor=request.user,
        date=selected_date,
        defaults={"seat_limit": request.user.daily_seat_limit},
    )

    if request.method == "POST":
        is_full = bool(request.data.get("is_full", availability.is_full))
        seat_limit_value = request.data.get("seat_limit")

        if seat_limit_value is not None:
            try:
                parsed_limit = int(seat_limit_value)
            except (TypeError, ValueError):
                return Response({"seat_limit": "Seat limit must be a number."}, status=status.HTTP_400_BAD_REQUEST)
            if parsed_limit < 1 or parsed_limit > 50:
                return Response({"seat_limit": "Seat limit must be between 1 and 50."}, status=status.HTTP_400_BAD_REQUEST)
            availability.seat_limit = parsed_limit

        availability.is_full = is_full
        availability.doctor_marked_full = is_full

        if not is_full:
            booked_count = Appointment.objects.filter(
                doctor=request.user,
                appointment_date=selected_date,
                status="scheduled",
            ).count()
            if booked_count >= availability.seat_limit:
                availability.is_full = True
                availability.doctor_marked_full = False

        availability.save()

    serializer = DoctorDayAvailabilitySerializer(availability)
    return Response(serializer.data)


@api_view(["GET"])
def doctor_appointments_view(request):
    if request.user.role != "doctor":
        return Response({"detail": "Only doctors can access this endpoint."}, status=status.HTTP_403_FORBIDDEN)

    queryset = Appointment.objects.select_related("user", "doctor").filter(doctor=request.user).order_by(
        "appointment_date", "appointment_time"
    )
    date_text = request.query_params.get("date", "").strip()
    if date_text:
        selected_date = parse_date(date_text)
        if selected_date is None:
            return Response({"detail": "A valid date is required (YYYY-MM-DD)."}, status=status.HTTP_400_BAD_REQUEST)
        queryset = queryset.filter(appointment_date=selected_date)

    serializer = AppointmentSerializer(queryset, many=True)
    return Response(serializer.data)
