import 'dart:convert';

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, List<String>> fields;
  final int? retryAfter;
  final int? attemptsRemaining;

  const ApiException(
    this.statusCode,
    this.code,
    this.message, {
    this.fields = const {},
    this.retryAfter,
    this.attemptsRemaining,
  });

  String? fieldError(String name) => fields[name]?.first;

  factory ApiException.fromResponse(int status, String body) {
    try {
      if (body.trim().isEmpty) {
        return const ApiException(
          500,
          'server_error',
          'Something went wrong. Please try again.',
        );
      }

      final dynamic decoded = jsonDecode(body);
      final map = decoded is Map
          ? decoded.cast<String, dynamic>()
          : <String, dynamic>{};
      final error = map['error'] is Map
          ? (map['error'] as Map).cast<String, dynamic>()
          : map;
      final fieldMap = error['fields'];
      final fields = <String, List<String>>{};
      if (fieldMap is Map) {
        for (final entry in fieldMap.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is List) {
            fields[key] = value.map((item) => item.toString()).toList();
          }
        }
      }

      final code = (error['code'] ?? map['code'] ?? 'server_error').toString();
      final message = (error['message'] ??
              map['detail'] ??
              'Something went wrong. Please try again.')
          .toString();

      return ApiException(
        status,
        code,
        message,
        fields: fields,
        retryAfter:
            error['retry_after'] is int ? error['retry_after'] as int : null,
        attemptsRemaining: error['attempts_remaining'] is int
            ? error['attempts_remaining'] as int
            : null,
      );
    } catch (_) {
      return const ApiException(
        500,
        'server_error',
        'Something went wrong. Please try again.',
      );
    }
  }

  static const ApiException networkError = ApiException(
    0,
    'network_error',
    "Can't reach the server. Check your connection and try again.",
  );
}
