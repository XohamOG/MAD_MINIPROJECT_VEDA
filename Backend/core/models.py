from django.conf import settings
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from django.utils import timezone

from .managers import UserManager


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=150)
    phone = models.CharField(max_length=20, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    blood_group = models.CharField(max_length=10, blank=True)
    emergency_contact_name = models.CharField(max_length=150, blank=True)
    emergency_contact_phone = models.CharField(max_length=20, blank=True)
    bp_reading = models.CharField(max_length=20, blank=True)
    sugar_level = models.CharField(max_length=20, blank=True)
    heart_rate = models.CharField(max_length=20, blank=True)
    weight = models.CharField(max_length=20, blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    joined_at = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    def __str__(self):
        return self.email


class Medication(TimeStampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="medications",
    )
    name = models.CharField(max_length=120)
    dosage = models.CharField(max_length=120)
    frequency = models.CharField(max_length=120)
    reminder_time = models.TimeField()
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.user.email})"


class Appointment(TimeStampedModel):
    STATUS_CHOICES = (
        ("scheduled", "Scheduled"),
        ("completed", "Completed"),
        ("cancelled", "Cancelled"),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="appointments",
    )
    doctor_name = models.CharField(max_length=150)
    specialty = models.CharField(max_length=120, blank=True)
    hospital_name = models.CharField(max_length=150, blank=True)
    appointment_date = models.DateField()
    appointment_time = models.TimeField()
    reason = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="scheduled")

    def __str__(self):
        return f"{self.doctor_name} - {self.appointment_date}"


class MedicalReport(TimeStampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="medical_reports",
    )
    title = models.CharField(max_length=180)
    report_type = models.CharField(max_length=100, blank=True)
    file = models.FileField(upload_to="reports/")
    report_date = models.DateField()
    notes = models.TextField(blank=True)

    def __str__(self):
        return self.title


class SOSLog(TimeStampedModel):
    STATUS_CHOICES = (
        ("triggered", "Triggered"),
        ("resolved", "Resolved"),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sos_logs",
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    message = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="triggered")
    triggered_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"SOS {self.user.email} @ {self.triggered_at}"
