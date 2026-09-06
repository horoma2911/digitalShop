enum UserRole { admin, client }

class User {
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final String? shopId;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.shopId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'password': password,
        'role': role.toString(),
        'shopId': shopId,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'],
        password: json['password'] ?? '',
        role: UserRole.values.firstWhere((e) => e.toString() == json['role']),
        shopId: json['shopId'],
      );
}
