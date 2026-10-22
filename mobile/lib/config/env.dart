class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const webRegistrationUrl =
      String.fromEnvironment('WEB_REGISTRATION_URL', defaultValue: '');

  static String get baseUrl => apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
}
