import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added: Required for input formatters
import 'package:provider/provider.dart';

import '../../../config/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class OtpScreen extends StatefulWidget {
  final OtpArgs args;
  const OtpScreen({super.key, required this.args});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  String? _codeError;
  bool _loading = false;
  bool _resending = false;
  late String _phone;
  late String _requestId;
  late bool _isRegistrationCode;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // Extract values directly from the strongly-typed OtpArgs object
    _phone = widget.args.phoneNumber;
    _requestId = widget.args.requestId;
    _isRegistrationCode = widget.args.isRegistrationCode;
    _startResendCountdown(widget.args.resendAfter);
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = seconds);
    if (seconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCountdown--);
      if (_resendCountdown <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 4) {
      setState(() => _codeError = 'Please enter the verification code');
      return;
    }

    setState(() {
      _codeError = null;
      _loading = true;
    });

    try {
      final result = await context.read<ApiClient>().verifyOtp(
            phoneNumber: _phone,
            requestId: _requestId,
            code: code,
          );
      if (!mounted) return;

      // Pass SetupArgs instead of a Map
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.setup,
        arguments: SetupArgs(setupToken: result.setupToken),
        (route) => false,
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _codeError = exception.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _resending = true);

    try {
      final result = await context.read<ApiClient>().requestOtp(_phone);
      if (!mounted) return;

      setState(() {
        _requestId = result.requestId;
        _codeError = null;
      });
      _startResendCountdown(result.resendAfter);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _codeError = exception.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _isRegistrationCode
                  ? 'Enter the code shown after web registration for $_phone.'
                  : 'Enter the code sent to $_phone',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6, // Restricts visual character length to 6
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6), // Strictly limits input to 6 digits
              ],
              decoration: InputDecoration(
                labelText: 'Verification Code',
                errorText: _codeError,
                errorMaxLines: 3,
                counterText: '', // Hides the built-in character count indicator for a cleaner look
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
            if (!_isRegistrationCode)
              TextButton(
                onPressed: (_resendCountdown > 0 || _resending)
                    ? null
                    : _resendCode,
                child: Text(
                  _resending
                      ? 'Sending...'
                      : _resendCountdown > 0
                          ? 'Resend code in ${_resendCountdown}s'
                          : 'Resend code',
                ),
              ),
          ],
        ),
      ),
    );
  }
}