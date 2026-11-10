import 'package:flutter/services.dart';
import 'package:chdc_counselling/core/secuirity/biometric_service.dart';
import 'package:chdc_counselling/core/secuirity/local_auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

class _FakeLocalAuthentication implements LocalAuthenticationClient {
  _FakeLocalAuthentication({
    this.deviceSupported = true,
    this.biometricsSupported = false,
    this.biometrics = const [],
    List<bool>? authenticationResults,
    this.exception,
    this.platformException,
  }) : authenticationResults = authenticationResults ?? [];

  final bool deviceSupported;
  @override
  Future<bool> get canCheckBiometrics async => biometricsSupported;
  final bool biometricsSupported;
  final List<BiometricType> biometrics;
  final List<bool> authenticationResults;
  final LocalAuthException? exception;
  PlatformException? platformException;
  int authenticationCalls = 0;
  String? requestedLocalizedReason;
  bool? requestedBiometricOnly;
  bool? requestedStickyAuth;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => biometrics;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required bool biometricOnly,
    required bool stickyAuth,
  }) async {
    authenticationCalls++;
    requestedLocalizedReason = localizedReason;
    requestedBiometricOnly = biometricOnly;
    requestedStickyAuth = stickyAuth;
    if (exception != null) throw exception!;
    if (platformException != null) {
      final error = platformException!;
      platformException = null;
      throw error;
    }
    if (authenticationResults.isEmpty) return false;
    return authenticationResults.removeAt(0);
  }
}

void main() {
  test('allows device credentials when biometrics are not enrolled', () async {
    final auth = _FakeLocalAuthentication(
      deviceSupported: true,
      biometricsSupported: true,
      authenticationResults: [true],
    );

    final authenticated = await BiometricService(auth: auth).authenticate(
      localizedReason: 'Open case',
    );

    expect(authenticated, isTrue);
    expect(auth.authenticationCalls, 1);
    expect(auth.requestedLocalizedReason, 'Open case');
    expect(auth.requestedBiometricOnly, isFalse);
    expect(auth.requestedStickyAuth, isTrue);
  });

  test('allows device credentials when biometric hardware is unavailable',
      () async {
    final auth = _FakeLocalAuthentication(
      deviceSupported: true,
      authenticationResults: [true],
    );

    final authenticated = await BiometricService(auth: auth).authenticate(
      localizedReason: 'Open case',
    );

    expect(authenticated, isTrue);
    expect(auth.requestedBiometricOnly, isFalse);
    expect(auth.requestedStickyAuth, isTrue);
  });

  test('checks enrollment before offering biometrics', () async {
    final auth = _FakeLocalAuthentication(
      biometricsSupported: true,
      biometrics: [BiometricType.fingerprint],
      authenticationResults: [true],
    );

    final authenticated = await BiometricService(auth: auth).authenticate(
      localizedReason: 'Open case',
    );

    expect(authenticated, isTrue);
    expect(auth.requestedBiometricOnly, isFalse);
    expect(auth.requestedStickyAuth, isTrue);
  });

  test('does not unlock when no local credentials are available', () async {
    final auth = _FakeLocalAuthentication(deviceSupported: false);

    final authenticated = await BiometricService(auth: auth).authenticate(
      localizedReason: 'Open case',
    );

    expect(authenticated, isFalse);
    expect(auth.requestedBiometricOnly, isFalse);
    expect(auth.requestedStickyAuth, isTrue);
    expect(auth.authenticationCalls, 1);
  });

  test('treats system prompt cancellation as a locked result', () async {
    final auth = _FakeLocalAuthentication(
      exception: const LocalAuthException(
        code: LocalAuthExceptionCode.userCanceled,
      ),
    );

    final authenticated = await BiometricService(auth: auth).authenticate(
      localizedReason: 'Open case',
    );

    expect(authenticated, isFalse);
    expect(auth.requestedBiometricOnly, isFalse);
    expect(auth.requestedStickyAuth, isTrue);
  });

  test('uses the device-credential fallback and handles platform errors', () async {
    final auth = _FakeLocalAuthentication(
      platformException: PlatformException(code: 'biometric_unavailable'),
    );

    final authenticated = await BiometricService(auth: auth).authenticate(
      localizedReason: 'Open case',
    );

    expect(authenticated, isFalse);
    expect(auth.authenticationCalls, 1);
    expect(auth.requestedBiometricOnly, isFalse);
    expect(auth.requestedStickyAuth, isTrue);
  });

  testWidgets('keeps a protected case closed until local auth succeeds',
      (tester) async {
    final auth = _FakeLocalAuthentication(
      authenticationResults: [false, true],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LocalAuthenticationGate(
          localizedReason: 'Authenticate to view this counselling case',
          biometricService: BiometricService(auth: auth),
          child: const Text('Sensitive case'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.authenticationCalls, 1);
    expect(
      auth.requestedLocalizedReason,
      'Authenticate to view this counselling case',
    );
    expect(auth.requestedBiometricOnly, isFalse);
    expect(auth.requestedStickyAuth, isTrue);
    expect(find.text('Sensitive case'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(auth.authenticationCalls, 2);
    expect(find.text('Sensitive case'), findsOneWidget);
  });
}
