import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _usernameError;
  String? _passwordError;
  String? _error;
  bool _passwordVisible = false;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _usernameError = _usernameController.text.trim().isEmpty
          ? 'This field is required.'
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? 'This field is required.'
          : null;
      _error = null;
    });
    if (_usernameError != null || _passwordError != null) return;

    setState(() => _loading = true);
    try {
      final session = await context.read<ApiClient>().login(
            username: _usernameController.text.trim(),
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
      if (exception.code == 'invalid_credentials') {
        _passwordController.clear();
        setState(() => _error = exception.message);
      } else if (exception.code == 'rate_limited') {
        setState(
          () => _error =
              'Too many attempts. Try again in ${exception.retryAfter ?? 0} seconds.',
        );
      } else if (exception.code == 'validation_error') {
        setState(() {
          _usernameError = exception.fieldError('username');
          _passwordError = exception.fieldError('password');
          _error = exception.message;
        });
      } else {
        setState(() => _error = exception.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Log in')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    errorText: _usernameError,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _passwordError,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip:
                          _passwordVisible ? 'Hide password' : 'Show password',
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
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                  label: 'Log in',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.phone),
                  child: const Text('First time here? Set up my account'),
                ),
              ],
            ),
          ),
        ),
      );
}
