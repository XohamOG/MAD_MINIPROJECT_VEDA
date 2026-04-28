class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bpReading,
    this.sugarLevel,
    this.heartRate,
    this.weight,
    this.doctorCategory,
    this.doctorArea,
    this.doctorCity,
    this.dailySeatLimit,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bpReading;
  final String? sugarLevel;
  final String? heartRate;
  final String? weight;
  final String? doctorCategory;
  final String? doctorArea;
  final String? doctorCity;
  final int? dailySeatLimit;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'patient',
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      bloodGroup: json['blood_group'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      bpReading: json['bp_reading'] as String?,
      sugarLevel: json['sugar_level'] as String?,
      heartRate: json['heart_rate'] as String?,
      weight: json['weight'] as String?,
      doctorCategory: json['doctor_category'] as String?,
      doctorArea: json['doctor_area'] as String?,
      doctorCity: json['doctor_city'] as String?,
      dailySeatLimit: json['daily_seat_limit'] as int?,
    );
  }

  AuthUser copyWith({
    String? fullName,
    String? phone,
    String? dateOfBirth,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bpReading,
    String? sugarLevel,
    String? heartRate,
    String? weight,
  }) {
    return AuthUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bpReading: bpReading ?? this.bpReading,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      heartRate: heartRate ?? this.heartRate,
      weight: weight ?? this.weight,
      doctorCategory: doctorCategory,
      doctorArea: doctorArea,
      doctorCity: doctorCity,
      dailySeatLimit: dailySeatLimit,
    );
  }
}
