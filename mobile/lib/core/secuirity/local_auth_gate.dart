import 'package:flutter/material.dart';

import 'biometric_service.dart';

class LocalAuthenticationGate extends StatefulWidget {
  const LocalAuthenticationGate({
    super.key,
    required this.localizedReason,
    required this.child,
    this.biometricService,
  });

  final String localizedReason;
  final Widget child;
  final BiometricService? biometricService;

  @override
  State<LocalAuthenticationGate> createState() =>
      _LocalAuthenticationGateState();
}

class _LocalAuthenticationGateState extends State<LocalAuthenticationGate> {
  late final BiometricService _biometricService =
      widget.biometricService ?? BiometricService();
  bool _isAuthenticating = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (!_isAuthenticating) {
      setState(() => _isAuthenticating = true);
    }
    final authenticated = await _biometricService.authenticate(
      localizedReason: widget.localizedReason,
    );
    if (!mounted) return;
    setState(() {
      _isAuthenticated = authenticated;
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) return widget.child;

    return Scaffold(
      appBar: AppBar(title: const Text("Verify it's you")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              Text(
                _isAuthenticating
                    ? 'Authenticate with biometrics or your device screen lock.'
                    : 'Use your device PIN, pattern, or password on the system prompt. If you cancelled, try again.',
                textAlign: TextAlign.center,
              ),
              if (_isAuthenticating) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ] else ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _authenticate,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
