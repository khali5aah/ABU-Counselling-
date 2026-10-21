import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/env.dart';
import 'config/routes.dart';
import 'core/api/api_client.dart';
import 'core/api/api_exception.dart';
import 'core/api/http_api_client.dart';
import 'core/api/mock_api_client.dart';
import 'core/models/user.dart';
import 'core/storage/token_storage.dart';
import 'core/validation/validators.dart';

void main() {
  runApp(const CrownbirdApp());
}

class CrownbirdApp extends StatelessWidget {
  const CrownbirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(
        apiClient: Env.useMock
            ? MockApiClient(SecureTokenStorage())
            : HttpApiClient(SecureTokenStorage()),
      ),
      child: MaterialApp(
        title: 'Crownbird E-Counselling',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        initialRoute: Routes.splash,
        onGenerateRoute: _routes,
      ),
    );
  }

  Route<dynamic> _routes(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case Routes.phone:
        return MaterialPageRoute(builder: (_) => const PhoneScreen());
      case Routes.otp:
        final args = settings.arguments as OtpArgs;
        return MaterialPageRoute(builder: (_) => OtpScreen(args: args));
      case Routes.setup:
        final args = settings.arguments as SetupArgs;
        return MaterialPageRoute(builder: (_) => SetupScreen(args: args));
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
    }
  }
}

class AuthController extends ChangeNotifier {
  AuthController({required this.apiClient});

  final ApiClient apiClient;
  User? user;
  bool isBusy = false;

  Future<void> bootstrap() async {
    if (isBusy) {
      return;
    }
    isBusy = true;
    notifyListeners();
    try {
      final hasSession = await apiClient.hasSession();
      if (!hasSession) {
        user = null;
        return;
      }
      user = await apiClient.me();
    } catch (_) {
      user = null;
      await apiClient.logout();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isBusy = true;
    notifyListeners();
    try {
      await apiClient.logout();
      user = null;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<AuthController>();
      await controller.bootstrap();
      if (!mounted) {
        return;
      }
      if (controller.user != null) {
        Navigator.pushNamedAndRemoveUntil(
            context, Routes.home, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, Routes.welcome, (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.school_rounded, size: 84, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Crownbird E-Counselling',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secure student onboarding and access to counselling support.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.phone),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.login),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    final normalized = normalizeNgPhone(value);
    if (normalized == null) {
      setState(() =>
          _error = 'Enter a valid Nigerian mobile number, e.g. 08031234567.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final api = context.read<AuthController>().apiClient;
      final result = await api.requestOtp(normalized);
      if (!mounted) {
        return;
      }
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
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your phone number',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                  'We will send a one-time code to verify your account.'),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  hintText: '0803 123 4567',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({required this.args, super.key});

  final OtpArgs args;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    final validationError = otpError(code);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final api = context.read<AuthController>().apiClient;
      final result = await api.verifyOtp(
        phoneNumber: widget.args.phoneNumber,
        requestId: widget.args.requestId,
        code: code,
      );
      if (!mounted) {
        return;
      }
      Navigator.pushNamed(
        context,
        Routes.setup,
        arguments: SetupArgs(setupToken: result.setupToken),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the 6-digit code',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(widget.args.message),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification code',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({required this.args, super.key});

  final SetupArgs args;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final usernameErrorValue = usernameError(_username.text);
    final passwordErrorValue = passwordError(_password.text);
    final confirmError = confirmPasswordError(_password.text, _confirm.text);
    if (usernameErrorValue != null ||
        passwordErrorValue != null ||
        confirmError != null) {
      setState(() =>
          _error = usernameErrorValue ?? passwordErrorValue ?? confirmError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthController>();
      final session = await auth.apiClient.setupAccount(
        setupToken: widget.args.setupToken,
        username: _username.text.trim(),
        password: _password.text,
      );
      auth.user = session.user;
      auth.notifyListeners();
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Text(
                'Create your account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController(text: 'student1');
  final _password = TextEditingController(text: 'Password123!');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userError = usernameError(_username.text);
    final passError = passwordError(_password.text);
    if (userError != null || passError != null) {
      setState(() => _error = userError ?? passError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthController>();
      final session = await auth.apiClient.login(
        username: _username.text.trim(),
        password: _password.text,
      );
      auth.user = session.user;
      auth.notifyListeners();
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, Routes.welcome, (route) => false);
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                user?.username ?? 'Student',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.school_rounded),
                  title: Text('Student portal'),
                  subtitle: Text('Your counselling experience is ready.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
