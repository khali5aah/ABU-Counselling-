import 'package:flutter/material.dart';

import 'config/env.dart';
import 'config/routes.dart';
import 'features/auth/screens/account_setup_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/phone_entry_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/home/home_screen.dart';

class ChdcApp extends StatelessWidget {
  const ChdcApp({super.key});

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case Routes.splash:
        page = const SplashScreen();
        break;
      case Routes.welcome:
        page = const WelcomeScreen();
        break;
      case Routes.phone:
        page = const PhoneEntryScreen();
        break;
      case Routes.otp:
        final otpArgs = settings.arguments;
        if (otpArgs is! OtpArgs) return _notFound(settings);
        page = OtpScreen(args: otpArgs);
        break;
      case Routes.setup:
        final setupArgs = settings.arguments;
        if (setupArgs is! SetupArgs) return _notFound(settings);
        page = AccountSetupScreen(args: setupArgs);
        break;
      case Routes.login:
        page = const LoginScreen();
        break;
      case Routes.home:
        page = const HomeScreen();
        break;
      default:
        return _notFound(settings);
    }
    return MaterialPageRoute<void>(
      builder: (_) => page,
      settings: settings,
    );
  }

  MaterialPageRoute<void> _notFound(RouteSettings settings) =>
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Page not found')),
          body: Center(
            child: Text('No page for ${settings.name ?? 'this route'}.'),
          ),
        ),
        settings: settings,
      );

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'CHDC E-Counselling',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          error: const Color(0xFFB3261E),
        ),
      ),
      initialRoute: Routes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
    return Env.useMock
        ? Banner(
            message: 'MOCK',
            location: BannerLocation.topEnd,
            textDirection: TextDirection.ltr,
            child: app,
          )
        : app;
  }
}
