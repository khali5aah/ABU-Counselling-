import '../models/auth_session.dart';
import '../models/otp_results.dart';
import '../models/user.dart';

abstract class ApiClient {
  Future<OtpRequestResult> requestOtp(String phoneNumber);
  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String requestId,
    required String code,
  });
  Future<AuthSession> setupAccount({
    required String setupToken,
    required String username,
    required String password,
  });
  Future<AuthSession> login({
    required String username,
    required String password,
  });
  Future<User> me();
  Future<void> logout();
  Future<bool> hasSession();
}
