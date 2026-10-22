import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/validation/validators.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../auth_controller.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({required this.args, super.key});

  final SetupArgs args;

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _usernameError;
  String? _passwordError;
  String? _confirmError;
  String? _error;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  bool _confirmingLeave = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _usernameError = usernameError(_usernameController.text);
      _passwordError = passwordError(_passwordController.text);
      _confirmError = confirmPasswordError(
        _passwordController.text,
        _confirmController.text,
      );
      _error = null;
    });
    if (_usernameError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      final session = await context.read<ApiClient>().setupAccount(
            setupToken: widget.args.setupToken,
            username: _usernameController.text.trim().toLowerCase(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.read<AuthController>().setSession(session);
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.home,
        (_) => false,
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      if (exception.code == 'setup_token_invalid') {
        await _showExpiredDialog(exception.message);
      } else if (exception.code == 'validation_error' ||
          exception.code == 'duplicate') {
        setState(() {
          _usernameError = exception.fieldError('username');
          _passwordError = exception.fieldError('password');
          _error = exception.fieldError('username') == null &&
                  exception.fieldError('password') == null
              ? exception.message
              : null;
        });
      } else {
        setState(() => _error = exception.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showExpiredDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.phone,
                ModalRoute.withName(Routes.welcome),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    if (_confirmingLeave) return;
    _confirmingLeave = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave account setup?'),
        content: const Text(
          "You'll need to verify your phone again.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    _confirmingLeave = false;
    if (leave == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.welcome,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_confirmLeave());
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Create your account')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    decoration: InputDecoration(
                      labelText: 'Username',
                      helperText: '3–30 characters: lowercase letters, digits or _',
                      errorText: _usernameError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _passwordError,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _passwordVisible
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: !_confirmVisible,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      errorText: _confirmError,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip:
                            _confirmVisible ? 'Hide password' : 'Show password',
                        onPressed: () => setState(
                          () => _confirmVisible = !_confirmVisible,
                        ),
                        icon: Icon(
                          _confirmVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    ErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  PrimaryButton(
                    label: 'Create account',
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
