class User {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final DateTime dateJoined;

  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateJoined: DateTime.parse(json['date_joined'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'date_joined': dateJoined.toIso8601String(),
      };
}
