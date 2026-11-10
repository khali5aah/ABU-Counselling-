import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/http_api_client.dart';
import 'core/api/mock_api_client.dart';
import 'config/env.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/auth_controller.dart';
import 'features/cases/case_controller.dart';
import 'config/routes.dart';

void main() {
  runApp(const ChdcApp());
}

class ChdcApp extends StatelessWidget {
  const ChdcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Provide the ApiClient (Mock or HTTP)
        Provider<ApiClient>(
          create: (_) {
            final tokenStorage = SecureTokenStorage(); 
            return Env.useMock
                ? MockApiClient(tokenStorage)
                : HttpApiClient(tokenStorage);
          },
        ),
        // 2. Pass the ApiClient into AuthController using ChangeNotifierProxyProvider
        ChangeNotifierProxyProvider<ApiClient, AuthController>(
          create: (context) => AuthController(context.read<ApiClient>())..bootstrap(),
          update: (context, api, previous) => previous ?? AuthController(api),
        ),
        ChangeNotifierProvider(create: (_) => CaseController()),
      ],
      child: MaterialApp(
        title: 'CHDC E-Counselling',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A5F),
            error: const Color(0xFFFB3261),
          ),
        ),
        initialRoute: Routes.welcome, // Or your SplashScreen route if you have one set up
        onGenerateRoute: Routes.onGenerateRoute,
        builder: (context, child) {
          if (Env.useMock && child != null) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Banner(
                message: 'MOCK API',
                location: BannerLocation.topEnd,
                color: Colors.orange,
                child: child,
              ),
            );
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}