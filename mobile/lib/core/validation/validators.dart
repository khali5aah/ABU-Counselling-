String? normalizeNgPhone(String raw) {
  var value = raw.replaceAll(RegExp(r'[\s\-().]'), '');
  if (value.startsWith('+234')) {
    // Already has the country code.
  } else if (value.startsWith('234')) {
    value = '+$value';
  } else if (value.startsWith('0') && value.length == 11) {
    value = '+234${value.substring(1)}';
  } else if (RegExp(r'^\d{10}$').hasMatch(value)) {
    value = '+234$value';
  }
  return RegExp(r'^\+234[789][01]\d{8}$').hasMatch(value) ? value : null;
}

String formatNgPhone(String e164) {
  if (!RegExp(r'^\+234\d{10}$').hasMatch(e164)) return e164;
  final digits = e164.substring(4);
  return '+234 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
}

String? phoneError(String raw) {
  if (raw.trim().isEmpty) return 'This field is required.';
  return normalizeNgPhone(raw) == null
      ? 'Enter a valid Nigerian mobile number, e.g. 08031234567.'
      : null;
}

String? usernameError(String raw) {
  final username = raw.trim().toLowerCase();
  if (!RegExp(r'^[a-z][a-z0-9_]{2,29}$').hasMatch(username)) {
    return 'Username must be 3–30 characters: lowercase letters, digits or underscore, starting with a letter.';
  }
  return null;
}

String? passwordError(String raw) {
  if (raw.length < 8) return 'Password must be at least 8 characters.';
  if (RegExp(r'^\d+$').hasMatch(raw)) {
    return "Password can't be entirely numeric.";
  }
  return null;
}

String? confirmPasswordError(String password, String confirm) =>
    password == confirm ? null : 'Passwords do not match.';

String? otpError(String raw) =>
    RegExp(r'^\d{6}$').hasMatch(raw) ? null : 'Enter the 6-digit code.';
