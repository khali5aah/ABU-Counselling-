import uuid

from django.db import models


class StudentRegistration(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    matric_number = models.CharField(max_length=30, unique=True)
    phone_number = models.CharField(max_length=14, unique=True)
    status = models.CharField(max_length=20, choices=[("active", "Active")], default="active")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "student_registrations"
        ordering = ["-created_at"]

    def __str__(self):
        return str(self.matric_number)
