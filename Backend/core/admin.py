from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Appointment, MedicalReport, Medication, SOSLog, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ("email", "full_name", "is_staff", "is_active")
    ordering = ("email",)
    search_fields = ("email", "full_name")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        (
            "Personal Info",
            {
                "fields": (
                    "full_name",
                    "phone",
                    "date_of_birth",
                    "blood_group",
                    "emergency_contact_name",
                    "emergency_contact_phone",
                )
            },
        ),
        ("Permissions", {"fields": ("is_staff", "is_active", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "joined_at")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "full_name", "password1", "password2", "is_staff", "is_active"),
            },
        ),
    )


admin.site.register(Medication)
admin.site.register(Appointment)
admin.site.register(MedicalReport)
admin.site.register(SOSLog)
