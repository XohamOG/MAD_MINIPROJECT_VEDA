class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
  });

  final int id;
  final String email;
  final String fullName;
  final String? phone;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}
