class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      bloodGroup: json['blood_group'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
    );
  }
}
