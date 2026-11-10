import 'package:flutter/material.dart';

import '../features/auth/screens/account_setup_screen.dart';
import '../features/auth/screens/dummy_chat_screen.dart'; // Add import for chat screen
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/phone_entry_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/cases/screens/case_details_screen.dart';// Add import for case detail screen
import '../core/secuirity/local_auth_gate.dart';
import '../features/navigation/main_tab_screen.dart';
import '../features/cases/screens/create_case_screen.dart'; // Adjust path if needed

class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const phone = '/setup/phone';
  static const otp = '/setup/otp';
  static const setup = '/setup/account';
  static const login = '/login';
  static const home = '/home';
  static const casesCreate = '/cases/create';
  static const caseDetails = '/cases/details';
  static const chat = '/chat';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case phone:
        return MaterialPageRoute(builder: (_) => const PhoneEntryScreen());
      case otp:
        final args = settings.arguments as OtpArgs;
        return MaterialPageRoute(builder: (_) => OtpScreen(args: args));
      case setup:
        final args = settings.arguments as SetupArgs;
        return MaterialPageRoute(builder: (_) => AccountSetupScreen(args: args));
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
        case casesCreate:
        return MaterialPageRoute(
          builder: (_) => const CreateCaseScreen(),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const MainTabScreen());
      case caseDetails:
        // Safely cast or convert arguments to avoid runtime type errors
        final args = settings.arguments;
        final caseData = args is Map
            ? args.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};
            
        return MaterialPageRoute(
          builder: (_) => LocalAuthenticationGate(
            localizedReason: 'Authenticate to view this counselling case',
            child: CaseDetailScreen(caseData: caseData),
          ),
        );
      case chat:
        return MaterialPageRoute(
          builder: (_) => LocalAuthenticationGate(
            localizedReason: 'Authenticate to open your counselling chat',
            child: DummyChatScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

class OtpArgs {
  const OtpArgs({
    required this.phoneNumber,
    required this.requestId,
    required this.resendAfter,
    required this.message,
    this.isRegistrationCode = false,
  });

  final String phoneNumber;
  final String requestId;
  final int resendAfter;
  final String message;
  final bool isRegistrationCode;
}

class SetupArgs {
  const SetupArgs({required this.setupToken});
  final String setupToken;
}