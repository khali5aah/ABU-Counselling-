import 'dart:async';

import '../models/auth_session.dart';
import '../models/otp_results.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

class MockApiClient implements ApiClient {
  MockApiClient(this._storage);

  final TokenStorage _storage;

  static const _mockAccess = 'mock-access-token';
  static const _mockRefresh = 'mock-refresh-token';
  static const _genericOtpMessage =
      'If this number is registered and not yet set up, a verification code has been sent by SMS.';

  Future<void> _delay() => Future<void>.delayed(
        const Duration(milliseconds: 600),
      );

  @override
  Future<OtpRequestResult> requestOtp(String phoneNumber) async {
    await _delay();
    if (phoneNumber == '+2348000000429') {
      throw const ApiException(
        statusCode: 429,
        code: 'rate_limited',
        message: 'Too many requests. Please wait and try again.',
        retryAfter: 42,
      );
    }
    return const OtpRequestResult(
      requestId: '00000000-0000-4000-8000-000000000001',
      message: _genericOtpMessage,
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
    await _delay();
    if (code == '123456') {
      return const OtpVerifyResult(
        setupToken: 'mock-setup-token',
        expiresIn: 600,
      );
    }
    if (code == '000000') {
      throw const ApiException(
        statusCode: 400,
        code: 'otp_expired',
        message: 'This code has expired. Request a new one.',
      );
    }
    if (code == '999999') {
      throw const ApiException(
        statusCode: 400,
        code: 'otp_attempts_exceeded',
        message: 'Too many incorrect attempts. Request a new code.',
      );
    }
    throw const ApiException(
      statusCode: 400,
      code: 'invalid_otp',
      message: 'The code is incorrect.',
      attemptsRemaining: 4,
    );
  }

  @override
  Future<AuthSession> setupAccount({
    required String setupToken,
    required String username,
    required String password,
  }) async {
    await _delay();
    if (setupToken != 'mock-setup-token') {
      throw const ApiException(
        statusCode: 400,
        code: 'setup_token_invalid',
        message: 'Your verification has expired. Please verify your phone number again.',
      );
    }
    if (username.toLowerCase() == 'taken_user') {
      throw const ApiException(
        statusCode: 409,
        code: 'duplicate',
        message: 'Some details are already registered.',
        fields: {
          'username': ['This username is taken.'],
        },
      );
    }
    final session = AuthSession(
      access: _mockAccess,
      refresh: _mockRefresh,
      user: _mockUser(username: username.trim().toLowerCase()),
    );
    await _storage.save(access: session.access, refresh: session.refresh);
    return session;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    await _delay();
    if (username.trim().toLowerCase() != 'student1' ||
        password != 'Password123!') {
      throw const ApiException(
        statusCode: 401,
        code: 'invalid_credentials',
        message: 'Incorrect username or password.',
      );
    }
    final session = AuthSession(
      access: _mockAccess,
      refresh: _mockRefresh,
      user: User(
        id: '00000000-0000-4000-8000-0000000000aa',
        username: 'student1',
        phoneNumber: '+2348031234567',
        dateJoined: DateTime.utc(2026, 10, 21, 9),
      ),
    );
    await _storage.save(access: session.access, refresh: session.refresh);
    return session;
  }

  @override
  Future<User> me() async {
    await _delay();
    if (await _storage.readAccess() != _mockAccess) {
      if (await _storage.readRefresh() != _mockRefresh) {
        await _storage.clear();
        throw const ApiException(
          statusCode: 401,
          code: 'token_invalid',
          message: 'Your session has expired. Please log in again.',
        );
      }
      await _storage.save(access: _mockAccess, refresh: _mockRefresh);
    }
    return _mockUser(username: 'student1');
  }

  @override
  Future<void> logout() async {
    await _delay();
    await _storage.clear();
  }

  @override
  Future<bool> hasSession() async {
    await _delay();
    return await _storage.readRefresh() != null;
  }

  User _mockUser({required String username}) => User(
        id: '00000000-0000-4000-8000-0000000000aa',
        username: username,
        phoneNumber: '+2348031234567',
        dateJoined: DateTime.utc(2026, 10, 21, 9),
      );
}
