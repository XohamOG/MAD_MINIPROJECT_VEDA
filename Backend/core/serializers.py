from django.contrib.auth import authenticate
from rest_framework import serializers

from .models import Appointment, MedicalReport, Medication, SOSLog, User


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
            "joined_at",
        )
        read_only_fields = ("id", "joined_at")


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ("email", "full_name", "password", "phone")

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
    class Meta:
        model = Appointment
        fields = "__all__"
        read_only_fields = ("id", "user", "created_at", "updated_at")


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
