import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/env.dart';
import '../../../config/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/validation/validators.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  String? _phoneError;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _phoneController.text;
    final validation = phoneError(raw);
    setState(() {
      _phoneError = validation;
      _error = null;
    });
    if (validation != null) return;

    final normalized = normalizeNgPhone(raw)!;
    setState(() => _loading = true);
    try {
      final result = await context.read<ApiClient>().requestOtp(normalized);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        Routes.otp,
        arguments: OtpArgs(
          phoneNumber: normalized,
          requestId: result.requestId,
          resendAfter: result.resendAfter,
          message: result.message,
        ),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        if (exception.code == 'validation_error') {
          _phoneError = exception.fieldError('phone_number');
        } else if (exception.code == 'rate_limited') {
          _error =
              'Please wait ${exception.retryAfter ?? 0} seconds before requesting another code.';
        } else {
          _error = exception.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Verify your phone')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter the phone number you used when registering on the web portal.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: '0803 123 4567',
                    errorText: _phoneError,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                  label: 'Send code',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Haven't registered yet? Register on the web portal first.",
                  textAlign: TextAlign.center,
                ),
                if (Env.webRegistrationUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    Env.webRegistrationUrl,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
