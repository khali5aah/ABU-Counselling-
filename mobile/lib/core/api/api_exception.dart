import 'dart:convert';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fields = const {},
    this.retryAfter,
    this.attemptsRemaining,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, List<String>> fields;
  final int? retryAfter;
  final int? attemptsRemaining;

  String? fieldError(String name) {
    final values = fields[name];
    return values == null || values.isEmpty ? null : values.first;
  }

  static const networkError = ApiException(
    statusCode: 0,
    code: 'network_error',
    message: "Can't reach the server. Check your connection and try again.",
  );

  factory ApiException.fromResponse(int status, String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>;
      final rawFields = error['fields'] as Map<String, dynamic>?;
      final fields = <String, List<String>>{};
      if (rawFields != null) {
        for (final entry in rawFields.entries) {
          final value = entry.value;
          if (value is List) {
            fields[entry.key] = value.map((item) => item.toString()).toList();
          } else {
            fields[entry.key] = [value.toString()];
          }
        }
      }
      return ApiException(
        statusCode: status,
        code: error['code'] as String,
        message: error['message'] as String,
        fields: fields,
        retryAfter: (error['retry_after'] as num?)?.toInt(),
        attemptsRemaining: (error['attempts_remaining'] as num?)?.toInt(),
      );
    } on Object {
      return ApiException(
        statusCode: status,
        code: 'server_error',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
