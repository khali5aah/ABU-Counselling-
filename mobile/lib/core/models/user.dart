class User {
  const User({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.dateJoined,
  });

  final String id;
  final String username;
  final String phoneNumber;
  final DateTime dateJoined;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        phoneNumber: json['phone_number'] as String,
        dateJoined: DateTime.parse(json['date_joined'] as String),
      );
}
