import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/auth_session.dart';
import '../../core/models/user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._api);

  final ApiClient _api;
  AuthStatus status = AuthStatus.unknown;
  User? user;

  Future<void> bootstrap() async {
    if (!await _api.hasSession()) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _api.me();
      status = AuthStatus.authenticated;
    } on ApiException {
      await _api.logout();
      user = null;
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void setSession(AuthSession session) {
    user = session.user;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    user = await _api.me();
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
