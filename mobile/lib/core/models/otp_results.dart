class OtpRequestResult {
  final String requestId;
  final String message;
  final int expiresIn;
  final int resendAfter;

  const OtpRequestResult({
    required this.requestId,
    required this.message,
    required this.expiresIn,
    required this.resendAfter,
  });

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) {
    return OtpRequestResult(
      requestId: json['request_id'] as String,
      message: json['message'] as String,
      expiresIn: json['expires_in'] as int,
      resendAfter: json['resend_after'] as int,
    );
  }
}

class OtpVerifyResult {
  final String setupToken;
  final int expiresIn;

  const OtpVerifyResult({
    required this.setupToken,
    required this.expiresIn,
  });

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResult(
      setupToken: json['setup_token'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}
