from django.contrib.auth.hashers import make_password
from django.db import migrations, models
import django.db.models.deletion


def seed_chembur_doctors(apps, schema_editor):
    User = apps.get_model("core", "User")

    doctors = [
        {
            "email": "ananya.shah@veda.doctor",
            "full_name": "Dr. Ananya Shah",
            "phone": "+91-9000000001",
            "doctor_category": "Cardiologist",
            "doctor_area": "Chembur",
            "doctor_city": "Mumbai",
            "daily_seat_limit": 6,
            "password": "Doctor@123",
        },
        {
            "email": "rohit.kulkarni@veda.doctor",
            "full_name": "Dr. Rohit Kulkarni",
            "phone": "+91-9000000002",
            "doctor_category": "Diabetologist",
            "doctor_area": "Chembur",
            "doctor_city": "Mumbai",
            "daily_seat_limit": 8,
            "password": "Doctor@123",
        },
        {
            "email": "neha.patil@veda.doctor",
            "full_name": "Dr. Neha Patil",
            "phone": "+91-9000000003",
            "doctor_category": "General Physician",
            "doctor_area": "Chembur",
            "doctor_city": "Mumbai",
            "daily_seat_limit": 10,
            "password": "Doctor@123",
        },
    ]

    for doc in doctors:
        defaults = {
            "full_name": doc["full_name"],
            "phone": doc["phone"],
            "role": "doctor",
            "doctor_category": doc["doctor_category"],
            "doctor_area": doc["doctor_area"],
            "doctor_city": doc["doctor_city"],
            "daily_seat_limit": doc["daily_seat_limit"],
            "is_active": True,
            "is_staff": False,
        }
        user, created = User.objects.get_or_create(email=doc["email"], defaults=defaults)

        if created:
            user.password = make_password(doc["password"])
            user.save(update_fields=["password"])
            continue

        changed_fields = []
        for field, value in defaults.items():
            if getattr(user, field) != value:
                setattr(user, field, value)
                changed_fields.append(field)

        if not user.password:
            user.password = make_password(doc["password"])
            changed_fields.append("password")

        if changed_fields:
            user.save(update_fields=changed_fields)


def noop(apps, schema_editor):
    return


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0002_user_health_metrics"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="daily_seat_limit",
            field=models.PositiveIntegerField(default=8),
        ),
        migrations.AddField(
            model_name="user",
            name="doctor_area",
            field=models.CharField(blank=True, max_length=120),
        ),
        migrations.AddField(
            model_name="user",
            name="doctor_category",
            field=models.CharField(blank=True, max_length=120),
        ),
        migrations.AddField(
            model_name="user",
            name="doctor_city",
            field=models.CharField(blank=True, max_length=120),
        ),
        migrations.AddField(
            model_name="user",
            name="role",
            field=models.CharField(
                choices=[("patient", "Patient"), ("doctor", "Doctor")],
                default="patient",
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name="appointment",
            name="doctor",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="doctor_appointments",
                to="core.user",
            ),
        ),
        migrations.CreateModel(
            name="DoctorDayAvailability",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("date", models.DateField()),
                ("seat_limit", models.PositiveIntegerField(default=8)),
                ("is_full", models.BooleanField(default=False)),
                ("doctor_marked_full", models.BooleanField(default=False)),
                (
                    "doctor",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="day_availability",
                        to="core.user",
                    ),
                ),
            ],
            options={"ordering": ("date",)},
        ),
        migrations.AlterUniqueTogether(
            name="doctordayavailability",
            unique_together={("doctor", "date")},
        ),
        migrations.RunPython(seed_chembur_doctors, noop),
    ]
