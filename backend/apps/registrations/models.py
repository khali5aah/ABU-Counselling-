import uuid

from django.db import models


class StudentRegistration(models.Model):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        COMPLETED = "COMPLETED", "Completed"
        EXPIRED = "EXPIRED", "Expired"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    matric_number = models.CharField(max_length=30, unique=True)
    phone_number = models.CharField(max_length=14, unique=True)
    has_consented = models.BooleanField(default=False)
    signup_code_hash = models.CharField(max_length=64, blank=True)
    signup_code_expires_at = models.DateTimeField(null=True, blank=True)
    signup_code_used_at = models.DateTimeField(null=True, blank=True)
    signup_code_attempts = models.PositiveSmallIntegerField(default=0)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "student_registrations"
        ordering = ["-created_at"]

    def __str__(self):
        return str(self.matric_number)