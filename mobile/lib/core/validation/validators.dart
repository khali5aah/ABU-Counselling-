String? normalizeNgPhone(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }

  String cleaned = value.replaceAll(RegExp(r'[\s\-()\.]'), '');
  String candidate;
  if (cleaned.startsWith('+234')) {
    candidate = cleaned;
  } else if (cleaned.startsWith('234')) {
    candidate = '+$cleaned';
  } else if (cleaned.startsWith('0') && cleaned.length == 11) {
    candidate = '+234${cleaned.substring(1)}';
  } else if (cleaned.length == 10 && RegExp(r'^\d+$').hasMatch(cleaned)) {
    candidate = '+234$cleaned';
  } else {
    return null;
  }

  if (!RegExp(r'^\+234[789][01]\d{8}$').hasMatch(candidate)) {
    return null;
  }

  return candidate;
}

String formatNgPhone(String e164) {
  final digits = e164.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 13 && digits.startsWith('234')) {
    final local = digits.substring(3);
    if (local.length >= 10) {
      return '+234 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
  }
  return e164;
}

String? phoneError(String raw) {
  if (raw.trim().isEmpty) {
    return 'This field is required.';
  }
  final normalized = normalizeNgPhone(raw);
  if (normalized == null) {
    return 'Enter a valid Nigerian mobile number, e.g. 08031234567.';
  }
  return null;
}

String? usernameError(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return 'This field is required.';
  }
  final normalized = value.toLowerCase();
  if (!RegExp(r'^[a-z][a-z0-9_]{2,29}$').hasMatch(normalized)) {
    return 'Username must be 3–30 characters: lowercase letters, digits or underscore, starting with a letter.';
  }
  return null;
}

String? passwordError(String raw) {
  if (raw.isEmpty) {
    return 'This field is required.';
  }
  if (raw.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  if (RegExp(r'^\d+$').hasMatch(raw)) {
    return "Password can't be entirely numeric.";
  }
  return null;
}

String? confirmPasswordError(String password, String confirm) {
  if (confirm.isEmpty) {
    return 'This field is required.';
  }
  if (password != confirm) {
    return 'Passwords do not match.';
  }
  return null;
}

String? otpError(String raw) {
  if (raw.trim().isEmpty) {
    return 'This field is required.';
  }
  if (!RegExp(r'^\d{6}$').hasMatch(raw)) {
    return 'Enter the 6-digit code.';
  }
  return null;
}
