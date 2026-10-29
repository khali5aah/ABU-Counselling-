import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../auth/screens/welcome_screen.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/phone_entry_screen.dart';
import '../auth/screens/otp_screen.dart';
import '../auth/screens/account_setup_screen.dart';
import '../cases/cases_list_screen.dart';
import '../cases/screens/create_case_screen.dart';
import '../cases/screens/case_details_screen.dart';
import 'main_tab_screen.dart';

class Routes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String phoneEntry = '/setup/phone';
  static const String otp = '/setup/otp';
  static const String accountSetup = '/setup/account';
  static const String cases = '/cases';
  static const String createCase = '/cases/create';
  static const String caseDetails = '/cases/details';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case phoneEntry:
        return MaterialPageRoute(builder: (_) => const PhoneEntryScreen());
      case otp:
        return MaterialPageRoute(
          builder: (_) => OtpScreen(args: args as OtpArgs),
        );
      case accountSetup:
        return MaterialPageRoute(
          builder: (_) => AccountSetupScreen(args: args as SetupArgs),
        );
      case cases:
        return MaterialPageRoute(builder: (_) => const CasesListScreen());
      case createCase:
        return MaterialPageRoute(builder: (_) => const CreateCaseScreen());
      case caseDetails:
        return MaterialPageRoute(
          builder: (_) => CaseDetailsScreen(caseItem: args),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const MainTabScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}