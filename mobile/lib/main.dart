import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/env.dart';
import 'core/api/api_client.dart';
import 'core/api/http_api_client.dart';
import 'core/api/mock_api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureTokenStorage();
  final ApiClient api =
      Env.useMock ? MockApiClient(storage) : HttpApiClient(storage);
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthController(api)),
      ],
      child: const ChdcApp(),
    ),
  );
}
