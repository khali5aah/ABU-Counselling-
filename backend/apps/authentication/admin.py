from django.contrib import admin

from apps.authentication.models import PhoneVerification, User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("username", "registration", "is_active", "date_joined")


@admin.register(PhoneVerification)
class PhoneVerificationAdmin(admin.ModelAdmin):
    list_display = ("id", "phone_masked", "created_at", "expires_at", "attempts", "verified_at", "setup_token_used_at")
    exclude = ("code_hash", "setup_token_hash")
    readonly_fields = ("id", "phone_masked", "created_at", "expires_at", "attempts", "verified_at", "setup_token_used_at")

    @admin.display(description="phone")
    def phone_masked(self, obj):
        if not obj or not obj.phone_number:
            return ""
        return obj.phone_number[:4] + "******" + obj.phone_number[-4:]
