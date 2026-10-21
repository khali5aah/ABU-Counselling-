import logging
import math
from typing import Any

from django.http import Http404
from rest_framework import status
from rest_framework.exceptions import (
    APIException,
    AuthenticationFailed,
    MethodNotAllowed,
    NotAuthenticated,
    NotFound,
    ParseError,
    PermissionDenied,
    Throttled,
    ValidationError as DRFValidationError,
)
from rest_framework.response import Response
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

logger = logging.getLogger("crownbird")


class ApiError(APIException):
    status_code = 400
    code = "error"
    default_detail = "Request failed."
    default_code = "error"

    def __init__(self, message=None, fields=None, extra=None):
        self.message = message or self.default_detail
        self.fields = fields
        self.extra = extra or {}
        super().__init__(detail=self.message)


def error_body(code, message, fields=None, **extra):
    payload = {"error": {"code": code, "message": message}}
    if fields is not None:
        payload["error"]["fields"] = fields
    if extra:
        payload["error"].update(extra)
    return payload


class DuplicateError(ApiError):
    status_code = 409
    code = "duplicate"
    default_detail = "Some details are already registered."


class InvalidOtpError(ApiError):
    status_code = 400
    code = "invalid_otp"
    default_detail = "The code is incorrect."


class OtpExpiredError(ApiError):
    status_code = 400
    code = "otp_expired"
    default_detail = "This code has expired. Request a new one."


class OtpAttemptsExceededError(ApiError):
    status_code = 400
    code = "otp_attempts_exceeded"
    default_detail = "Too many incorrect attempts. Request a new code."


class SetupTokenInvalidError(ApiError):
    status_code = 400
    code = "setup_token_invalid"
    default_detail = "Your verification has expired. Please verify your phone number again."


class InvalidCredentialsError(ApiError):
    status_code = 401
    code = "invalid_credentials"
    default_detail = "Incorrect username or password."


class RateLimitedError(ApiError):
    status_code = 429
    code = "rate_limited"
    default_detail = "Too many requests. Please wait and try again."

    def __init__(self, retry_after, message=None, fields=None, extra=None):
        payload_extra = {"retry_after": int(retry_after)}
        if extra:
            payload_extra.update(extra)
        super().__init__(message=message or self.default_detail, fields=fields, extra=payload_extra)


def flatten_validation_error(detail, parent_key=""):
    flattened = {}

    if isinstance(detail, dict):
        for key, value in detail.items():
            new_key = f"{parent_key}.{key}" if parent_key else key
            if isinstance(value, dict):
                flattened.update(flatten_validation_error(value, new_key))
            elif isinstance(value, list):
                flattened[new_key] = [str(item) for item in value]
            else:
                flattened[new_key] = [str(value)]
        return flattened

    if isinstance(detail, list):
        return {"non_field_errors": [str(item) for item in detail]}

    return {"non_field_errors": [str(detail)]}


def api_exception_handler(exc, context):
    if isinstance(exc, ApiError):
        response = Response(
            error_body(exc.code, exc.message, exc.fields, **exc.extra),
            status=exc.status_code,
        )
        if exc.status_code == 401 and getattr(exc, "auth_header", None):
            response["WWW-Authenticate"] = exc.auth_header
        return response

    if isinstance(exc, DRFValidationError):
        fields = flatten_validation_error(exc.detail)
        payload = error_body(
            "validation_error",
            "Please correct the highlighted fields.",
            fields=fields if fields else None,
        )
        response = Response(payload, status=400)
        return response

    if isinstance(exc, ParseError):
        return Response(error_body("validation_error", "Malformed JSON request body."), status=400)

    if isinstance(exc, NotAuthenticated):
        response = Response(error_body("not_authenticated", "Authentication credentials were not provided."), status=401)
        if getattr(exc, "auth_header", None):
            response["WWW-Authenticate"] = exc.auth_header
        return response

    if isinstance(exc, (InvalidToken, TokenError, AuthenticationFailed)):
        response = Response(error_body("token_invalid", "Your session has expired. Please log in again."), status=401)
        if getattr(exc, "auth_header", None):
            response["WWW-Authenticate"] = exc.auth_header
        return response

    if isinstance(exc, PermissionDenied):
        return Response(error_body("permission_denied", "You do not have permission to do this."), status=403)

    if isinstance(exc, (NotFound, Http404)):
        return Response(error_body("not_found", "Not found."), status=404)

    if isinstance(exc, MethodNotAllowed):
        return Response(error_body("method_not_allowed", "Method not allowed."), status=405)

    if isinstance(exc, Throttled):
        retry_after = int(math.ceil(exc.wait or 1))
        response = Response(
            error_body("rate_limited", "Too many requests. Please wait and try again.", retry_after=retry_after),
            status=429,
        )
        response["Retry-After"] = str(retry_after)
        return response

    logger.exception("Unhandled API exception")
    return Response(error_body("server_error", "Something went wrong. Please try again."), status=500)
