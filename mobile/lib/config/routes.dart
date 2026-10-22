class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const phone = '/setup/phone';
  static const otp = '/setup/otp';
  static const setup = '/setup/account';
  static const login = '/login';
  static const home = '/home';
}

class OtpArgs {
  const OtpArgs({
    required this.phoneNumber,
    required this.requestId,
    required this.resendAfter,
    required this.message,
  });

  final String phoneNumber;
  final String requestId;
  final int resendAfter;
  final String message;
}

class SetupArgs {
  const SetupArgs({required this.setupToken});

  final String setupToken;
}
