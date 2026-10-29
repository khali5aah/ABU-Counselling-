import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Checks if hardware supports biometrics and device pin/passcode.
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Prompts user for Face ID / Touch ID / Passcode unlock.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return true; // Fallback if biometrics aren't configured on device

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}