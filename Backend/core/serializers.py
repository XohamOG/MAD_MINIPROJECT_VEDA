from django.contrib.auth import authenticate
from rest_framework import serializers

from .models import Appointment, DoctorDayAvailability, MedicalReport, Medication, SOSLog, User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "full_name",
            "phone",
            "date_of_birth",
            "blood_group",
            "emergency_contact_name",
            "emergency_contact_phone",
            "bp_reading",
            "sugar_level",
            "heart_rate",
            "weight",
            "role",
            "doctor_category",
            "doctor_area",
            "doctor_city",
            "daily_seat_limit",
            "joined_at",
        )
        read_only_fields = ("id", "joined_at", "role")


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    role = serializers.ChoiceField(choices=["patient", "doctor"], default="patient")
    daily_seat_limit = serializers.IntegerField(required=False, min_value=1, max_value=50)

    class Meta:
        model = User
        fields = (
            "email",
            "full_name",
            "password",
            "role",
            "phone",
            "date_of_birth",
            "blood_group",
            "emergency_contact_name",
            "emergency_contact_phone",
            "bp_reading",
            "sugar_level",
            "heart_rate",
            "weight",
            "doctor_category",
            "doctor_area",
            "doctor_city",
            "daily_seat_limit",
        )

    def validate(self, attrs):
        role = attrs.get("role", "patient")

        if role == "doctor":
            missing = []
            for key in ("doctor_category", "doctor_area", "doctor_city"):
                value = attrs.get(key)
                if not isinstance(value, str) or not value.strip():
                    missing.append(key)
            if missing:
                raise serializers.ValidationError(
                    {field: "This field is required for doctor account." for field in missing}
                )
            attrs["daily_seat_limit"] = attrs.get("daily_seat_limit", 8)
        else:
            # Patients should not carry doctor-only profile fields.
            attrs["doctor_category"] = ""
            attrs["doctor_area"] = ""
            attrs["doctor_city"] = ""
            attrs["daily_seat_limit"] = 8

        return attrs

    def create(self, validated_data):
        password = validated_data.pop("password")
        return User.objects.create_user(password=password, **validated_data)


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs.get("email")
        password = attrs.get("password")
        user = authenticate(request=self.context.get("request"), username=email, password=password)
        if not user:
            raise serializers.ValidationError("Invalid email or password.")
        attrs["user"] = user
        return attrs


class MedicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medication
        fields = "__all__"
        read_only_fields = ("id", "user", "created_at", "updated_at")


class AppointmentSerializer(serializers.ModelSerializer):
    doctor_id = serializers.IntegerField(write_only=True, required=False)
    patient_name = serializers.CharField(source="user.full_name", read_only=True)
    patient_email = serializers.CharField(source="user.email", read_only=True)
    doctor_area = serializers.CharField(source="doctor.doctor_area", read_only=True)
    doctor_city = serializers.CharField(source="doctor.doctor_city", read_only=True)

    class Meta:
        model = Appointment
        fields = (
            "id",
            "user",
            "doctor",
            "doctor_id",
            "doctor_name",
            "specialty",
            "doctor_area",
            "doctor_city",
            "hospital_name",
            "appointment_date",
            "appointment_time",
            "reason",
            "status",
            "patient_name",
            "patient_email",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "user",
            "doctor",
            "doctor_name",
            "specialty",
            "hospital_name",
            "status",
            "patient_name",
            "patient_email",
            "created_at",
            "updated_at",
        )

    def validate(self, attrs):
        request = self.context.get("request")
        if request and request.method == "POST":
            doctor_id = attrs.get("doctor_id")
            if doctor_id is None:
                raise serializers.ValidationError({"doctor_id": "Please select a doctor."})

            doctor = User.objects.filter(id=doctor_id, role="doctor", is_active=True).first()
            if doctor is None:
                raise serializers.ValidationError({"doctor_id": "Selected doctor is not available."})

            attrs["doctor"] = doctor
            attrs["doctor_name"] = doctor.full_name
            attrs["specialty"] = doctor.doctor_category
            attrs["hospital_name"] = f"{doctor.doctor_area}, {doctor.doctor_city}".strip(", ")

        return attrs


class DoctorListSerializer(serializers.ModelSerializer):
    seats_booked = serializers.SerializerMethodField()
    seats_remaining = serializers.SerializerMethodField()
    is_full_for_date = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "full_name",
            "email",
            "phone",
            "doctor_category",
            "doctor_area",
            "doctor_city",
            "daily_seat_limit",
            "seats_booked",
            "seats_remaining",
            "is_full_for_date",
        )

    def _selected_date(self):
        selected_date = self.context.get("selected_date")
        return selected_date

    def _booking_snapshot(self, doctor):
        selected_date = self._selected_date()
        if selected_date is None:
            return {
                "booked": 0,
                "remaining": doctor.daily_seat_limit,
                "is_full": False,
            }

        booked = Appointment.objects.filter(
            doctor=doctor,
            appointment_date=selected_date,
            status="scheduled",
        ).count()
        availability = DoctorDayAvailability.objects.filter(doctor=doctor, date=selected_date).first()
        seat_limit = availability.seat_limit if availability else doctor.daily_seat_limit
        is_full = availability.is_full if availability else booked >= seat_limit
        remaining = max(seat_limit - booked, 0)
        if is_full:
            remaining = 0

        return {
            "booked": booked,
            "remaining": remaining,
            "is_full": is_full,
        }

    def get_seats_booked(self, obj):
        return self._booking_snapshot(obj)["booked"]

    def get_seats_remaining(self, obj):
        return self._booking_snapshot(obj)["remaining"]

    def get_is_full_for_date(self, obj):
        return self._booking_snapshot(obj)["is_full"]


class DoctorDayAvailabilitySerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source="doctor.full_name", read_only=True)
    seats_booked = serializers.SerializerMethodField()
    seats_remaining = serializers.SerializerMethodField()

    class Meta:
        model = DoctorDayAvailability
        fields = (
            "id",
            "doctor",
            "doctor_name",
            "date",
            "seat_limit",
            "is_full",
            "doctor_marked_full",
            "seats_booked",
            "seats_remaining",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "doctor",
            "doctor_name",
            "doctor_marked_full",
            "seats_booked",
            "seats_remaining",
            "created_at",
            "updated_at",
        )

    def get_seats_booked(self, obj):
        return Appointment.objects.filter(
            doctor=obj.doctor,
            appointment_date=obj.date,
            status="scheduled",
        ).count()

    def get_seats_remaining(self, obj):
        booked = self.get_seats_booked(obj)
        if obj.is_full:
            return 0
        return max(obj.seat_limit - booked, 0)


class MedicalReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicalReport
        fields = "__all__"
        read_only_fields = ("id", "user", "created_at", "updated_at")


class SOSLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SOSLog
        fields = "__all__"
        read_only_fields = ("id", "user", "created_at", "updated_at", "triggered_at")
