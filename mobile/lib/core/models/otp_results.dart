class OtpRequestResult {
  const OtpRequestResult({
    required this.requestId,
    required this.message,
    required this.expiresIn,
    required this.resendAfter,
    this.isRegistrationCode = false,
  });

  final String requestId;
  final String message;
  final int expiresIn;
  final int resendAfter;
  final bool isRegistrationCode;

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) =>
      OtpRequestResult(
        requestId: json['request_id'] as String,
        message: json['message'] as String,
        expiresIn: json['expires_in'] as int,
        resendAfter: json['resend_after'] as int,
        isRegistrationCode: json['is_registration_code'] as bool? ?? false,
      );
}

class OtpVerifyResult {
  const OtpVerifyResult({required this.setupToken, required this.expiresIn});

  final String setupToken;
  final int expiresIn;

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) =>
      OtpVerifyResult(
        setupToken: json['setup_token'] as String,
        expiresIn: json['expires_in'] as int,
      );
}
