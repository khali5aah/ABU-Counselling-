from django.contrib import admin

from apps.registrations.models import StudentRegistration


@admin.register(StudentRegistration)
class StudentRegistrationAdmin(admin.ModelAdmin):
    list_display = ("first_name", "last_name", "matric_number", "phone_number", "created_at")
    search_fields = ("matric_number", "phone_number")
