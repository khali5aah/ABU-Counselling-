import 'package:flutter_test/flutter_test.dart';
import 'package:chdc_counselling/core/api/api_exception.dart';
import 'package:chdc_counselling/core/api/mock_api_client.dart';
import 'package:chdc_counselling/core/storage/token_storage.dart';

void main() {
  late InMemoryTokenStorage storage;
  late MockApiClient api;

  setUp(() {
    storage = InMemoryTokenStorage();
    api = MockApiClient(storage);
  });

  test('request OTP returns generic success and rate-limit trigger', () async {
    final result = await api.requestOtp('+2348031234567');
    expect(result.requestId, '00000000-0000-4000-8000-000000000001');
    expect(result.expiresIn, 300);
    expect(result.resendAfter, 60);
    expect(result.message, contains('If this number is registered'));

    await expectLater(
      api.requestOtp('+2348000000429'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'rate_limited')
            .having((error) => error.retryAfter, 'retryAfter', 42),
      ),
    );
  });

  test('verification mock codes follow the contract scenarios', () async {
    expect(
      (await api.verifyOtp(
        phoneNumber: '+2348031234567',
        requestId: 'request',
        code: '123456',
      ))
          .setupToken,
      'mock-setup-token',
    );

    for (final scenario in {
      '000000': 'otp_expired',
      '999999': 'otp_attempts_exceeded',
      '111111': 'invalid_otp',
    }.entries) {
      await expectLater(
        api.verifyOtp(
          phoneNumber: '+2348031234567',
          requestId: 'request',
          code: scenario.key,
        ),
        throwsA(isA<ApiException>().having(
          (error) => error.code,
          'code',
          scenario.value,
        )),
      );
    }
  });

  test('setup rejects invalid token and duplicate username', () async {
    await expectLater(
      api.setupAccount(
        setupToken: 'wrong',
        username: 'amina_b',
        password: 'S3cure!pass',
      ),
      throwsA(isA<ApiException>().having(
        (error) => error.code,
        'code',
        'setup_token_invalid',
      )),
    );
    await expectLater(
      api.setupAccount(
        setupToken: 'mock-setup-token',
        username: 'taken_user',
        password: 'S3cure!pass',
      ),
      throwsA(isA<ApiException>().having(
        (error) => error.fieldError('username'),
        'username error',
        'This username is taken.',
      )),
    );
  });

  test('setup and login save tokens, me reads user, logout clears tokens',
      () async {
    final session = await api.setupAccount(
      setupToken: 'mock-setup-token',
      username: 'amina_b',
      password: 'S3cure!pass',
    );
    expect(session.user.username, 'amina_b');
    expect(await storage.readAccess(), 'mock-access-token');
    expect(await storage.readRefresh(), 'mock-refresh-token');
    expect((await api.me()).phoneNumber, '+2348031234567');
    expect(await api.hasSession(), isTrue);

    await api.logout();
    expect(await storage.readAccess(), isNull);
    expect(await api.hasSession(), isFalse);

    final loggedIn = await api.login(
      username: 'STUDENT1',
      password: 'Password123!',
    );
    expect(loggedIn.user.username, 'student1');
    expect(await storage.readRefresh(), 'mock-refresh-token');
    await expectLater(
      api.login(username: 'other', password: 'wrong'),
      throwsA(isA<ApiException>().having(
        (error) => error.code,
        'code',
        'invalid_credentials',
      )),
    );
  });

  test('me refreshes a valid mock refresh token and clears an invalid session',
      () async {
    await storage.save(access: 'expired-access', refresh: 'mock-refresh-token');
    expect((await api.me()).username, 'student1');
    expect(await storage.readAccess(), 'mock-access-token');

    await storage.save(access: 'expired-access', refresh: 'invalid-refresh');
    await expectLater(
      api.me(),
      throwsA(isA<ApiException>().having(
        (error) => error.code,
        'code',
        'token_invalid',
      )),
    );
    expect(await storage.readRefresh(), isNull);
  });
}
