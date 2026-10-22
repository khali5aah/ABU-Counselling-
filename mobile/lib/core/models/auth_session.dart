import 'user.dart';

class AuthSession {
  const AuthSession({
    required this.access,
    required this.refresh,
    required this.user,
  });

  final String access;
  final String refresh;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
