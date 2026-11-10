import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class LocalAuthenticationClient {
  Future<bool> get canCheckBiometrics;
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> isDeviceSupported();
  Future<bool> authenticate({
    required String localizedReason,
    required bool biometricOnly,
    required bool stickyAuth,
  });
}

class _PluginLocalAuthenticationClient implements LocalAuthenticationClient {
  final LocalAuthentication _auth;

  _PluginLocalAuthenticationClient(this._auth);

  @override
  Future<bool> get canCheckBiometrics => _auth.canCheckBiometrics;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() =>
      _auth.getAvailableBiometrics();

  @override
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required bool biometricOnly,
    required bool stickyAuth,
  }) {
    return _auth.authenticate(
      localizedReason: localizedReason,
      biometricOnly: biometricOnly,
      persistAcrossBackgrounding: stickyAuth,
    );
  }
}

class BiometricService {
  final LocalAuthenticationClient _auth;

  BiometricService({LocalAuthenticationClient? auth})
      : _auth = auth ?? _PluginLocalAuthenticationClient(LocalAuthentication());

  /// Returns true only when at least one biometric is enrolled and usable.
  Future<bool> isBiometricsAvailable() async {
    try {
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Uses Android's system prompt with device credentials allowed as fallback.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        stickyAuth: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
