import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/validation/validators.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({required this.args, super.key});

  final OtpArgs args;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  late int _countdown;
  String? _codeError;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _countdown = widget.args.resendAfter;
    _startCountdown(_countdown);
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _countdown = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) _countdown--;
        if (_countdown == 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text;
    final validation = otpError(code);
    setState(() {
      _codeError = validation;
      _error = null;
    });
    if (validation != null) return;
    setState(() => _loading = true);
    try {
      final result = await context.read<ApiClient>().verifyOtp(
            phoneNumber: widget.args.phoneNumber,
            requestId: widget.args.requestId,
            code: code,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        Routes.setup,
        arguments: SetupArgs(setupToken: result.setupToken),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        if (exception.code == 'invalid_otp') {
          _codeError = exception.attemptsRemaining == null
              ? exception.message
              : 'The code is incorrect. ${exception.attemptsRemaining} attempts left.';
          _codeController.clear();
        } else if (exception.code == 'otp_expired' ||
            exception.code == 'otp_attempts_exceeded') {
          _error = exception.message;
        } else {
          _error = exception.message;
        }
      });
      if (exception.code == 'otp_expired' ||
          exception.code == 'otp_attempts_exceeded') {
        _startCountdown(0);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
      _codeError = null;
    });
    try {
      final result = await context
          .read<ApiClient>()
          .requestOtp(widget.args.phoneNumber);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        Routes.otp,
        arguments: OtpArgs(
          phoneNumber: widget.args.phoneNumber,
          requestId: result.requestId,
          resendAfter: result.resendAfter,
          message: result.message,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If this number is registered, a new code has been sent.',
          ),
        ),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception.message);
      if (exception.code == 'rate_limited') {
        _startCountdown(exception.retryAfter ?? 0);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _resendLabel {
    final minutes = (_countdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdown % 60).toString().padLeft(2, '0');
    return 'Resend code in $minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Enter code')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.args.message),
                const SizedBox(height: 8),
                Text('Number: ${formatNgPhone(widget.args.phoneNumber)}'),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(letterSpacing: 8, fontSize: 22),
                  decoration: InputDecoration(
                    labelText: '6-digit code',
                    errorText: _codeError,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                  label: 'Verify',
                  isLoading: _loading,
                  onPressed: _verify,
                ),
                TextButton(
                  onPressed:
                      _countdown > 0 || _loading ? null : _resend,
                  child: Text(
                    _countdown > 0 ? _resendLabel : 'Resend code',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
