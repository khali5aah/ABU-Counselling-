import 'dart:async';

import '../models/auth_session.dart';
import '../models/otp_results.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

class MockApiClient implements ApiClient {
  MockApiClient(this.storage);

  final TokenStorage storage;

  @override
  Future<OtpRequestResult> requestOtp(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final normalized = phoneNumber.trim();
    if (normalized == '+2348000000429') {
      throw const ApiException(
        429,
        'rate_limited',
        'Too many requests. Please wait and try again.',
        retryAfter: 42,
      );
    }
    return const OtpRequestResult(
      requestId: '00000000-0000-4000-8000-000000000001',
      message:
          'If this number is registered and not yet set up, a verification code has been sent by SMS.',
      expiresIn: 300,
      resendAfter: 60,
    );
  }

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String requestId,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (code == '123456') {
      return const OtpVerifyResult(
          setupToken: 'mock-setup-token', expiresIn: 600);
    }
    if (code == '000000') {
      throw const ApiException(
        400,
        'otp_expired',
        'This code has expired. Request a new one.',
      );
    }
    if (code == '999999') {
      throw const ApiException(
        400,
        'otp_attempts_exceeded',
        'Too many incorrect attempts. Request a new code.',
      );
    }
    throw const ApiException(
      400,
      'invalid_otp',
      'The code is incorrect.',
      attemptsRemaining: 4,
    );
  }

  @override
  Future<AuthSession> setupAccount({
    required String setupToken,
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (setupToken != 'mock-setup-token') {
      throw const ApiException(
        400,
        'setup_token_invalid',
        'Your verification has expired. Please verify your phone number again.',
      );
    }
    if (username == 'taken_user') {
      throw const ApiException(
        409,
        'duplicate',
        'Some details are already registered.',
        fields: {
          'username': ['This username is taken.'],
        },
      );
    }
    await storage.save(
        access: 'mock-access-token', refresh: 'mock-refresh-token');
    return AuthSession(
      access: 'mock-access-token',
      refresh: 'mock-refresh-token',
      user: User(
        id: '00000000-0000-4000-8000-0000000000aa',
        username: username.toLowerCase(),
        firstName: 'Amina',
        lastName: 'Bello',
        dateJoined: DateTime.utc(2026, 10, 21, 9),
      ),
    );
  }

  @override
  Future<AuthSession> login(
      {required String username, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (username == 'student1' && password == 'Password123!') {
      await storage.save(
          access: 'mock-access-token', refresh: 'mock-refresh-token');
      return AuthSession(
        access: 'mock-access-token',
        refresh: 'mock-refresh-token',
        user: User(
          id: '00000000-0000-4000-8000-0000000000aa',
          username: 'student1',
          firstName: 'Amina',
          lastName: 'Bello',
          dateJoined: DateTime.utc(2026, 10, 21, 9),
        ),
      );
    }
    throw const ApiException(
      401,
      'invalid_credentials',
      'Incorrect username or password.',
    );
  }

  @override
  Future<User> me() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final access = await storage.readAccess();
    if (access == 'mock-access-token') {
      return User(
        id: '00000000-0000-4000-8000-0000000000aa',
        username: 'student1',
        firstName: 'Amina',
        lastName: 'Bello',
        dateJoined: DateTime.utc(2026, 10, 21, 9),
      );
    }
    throw const ApiException(
      401,
      'token_invalid',
      'Your session has expired. Please log in again.',
    );
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await storage.clear();
  }

  @override
  Future<bool> hasSession() async {
    final refresh = await storage.readRefresh();
    return refresh != null && refresh.isNotEmpty;
  }
}
