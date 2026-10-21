import 'user.dart';

class AuthSession {
  final String access;
  final String refresh;
  final User user;

  const AuthSession({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'access': access,
        'refresh': refresh,
        'user': user.toJson(),
      };
}
