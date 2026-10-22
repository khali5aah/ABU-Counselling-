import uuid

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.utils import timezone


class UserManager(BaseUserManager):
    def create_user(self, username, password=None, registration=None, **extra):
        username = (username or "").strip().lower()
        if not username:
            raise ValueError("The username must be set.")
        user = self.model(username=username, registration=registration, **extra)
        if password is not None:
            user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, password=None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        if extra.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        return self.create_user(username, password=password, registration=None, **extra)


class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = models.CharField(max_length=30, unique=True)
    registration = models.OneToOneField(
        "registrations.StudentRegistration",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="account",
    )
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = []

    objects = UserManager()

    class Meta:
        db_table = "user_accounts"

    def save(self, *args, **kwargs):
        self.username = (self.username or "").strip().lower()
        super().save(*args, **kwargs)

    @property
    def first_name(self):
        return self.registration.first_name if self.registration else ""

    @property
    def last_name(self):
        return self.registration.last_name if self.registration else ""

    @property
    def phone_number(self):
        return self.registration.phone_number if self.registration else ""

    def __str__(self):
        return self.username


class PhoneVerification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    registration = models.ForeignKey(
        "registrations.StudentRegistration",
        on_delete=models.CASCADE,
        related_name="phone_verifications",
    )
    phone_number = models.CharField(max_length=14, db_index=True)
    code_hash = models.CharField(max_length=64)
    expires_at = models.DateTimeField()
    attempts = models.PositiveSmallIntegerField(default=0)
    max_attempts = models.PositiveSmallIntegerField()
    verified_at = models.DateTimeField(null=True, blank=True)
    invalidated_at = models.DateTimeField(null=True, blank=True)
    setup_token_hash = models.CharField(max_length=64, null=True, blank=True, unique=True)
    setup_token_expires_at = models.DateTimeField(null=True, blank=True)
    setup_token_used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "phone_verifications"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.phone_number} ({self.registration})"
