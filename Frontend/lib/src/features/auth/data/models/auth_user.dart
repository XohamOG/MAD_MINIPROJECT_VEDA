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
    this.bpReading,
    this.sugarLevel,
    this.heartRate,
    this.weight,
  });

  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bpReading;
  final String? sugarLevel;
  final String? heartRate;
  final String? weight;

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
      bpReading: json['bp_reading'] as String?,
      sugarLevel: json['sugar_level'] as String?,
      heartRate: json['heart_rate'] as String?,
      weight: json['weight'] as String?,
    );
  }
}
