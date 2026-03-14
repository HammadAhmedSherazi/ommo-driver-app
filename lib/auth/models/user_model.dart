class UserModel {
  const UserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.employmentType,
    this.cdlLicenseNumber,
    this.licenseState,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? employmentType;
  final String? cdlLicenseNumber;
  final String? licenseState;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return email ?? 'User';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_Name'] as String? ?? json['firstName'] as String?,
      lastName: json['last_Name'] as String? ?? json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      employmentType: json['employment_Type'] as String? ?? json['employmentType'] as String?,
      cdlLicenseNumber: json['cdl_License_Number'] as String? ?? json['cdlLicenseNumber'] as String?,
      licenseState: json['license_State'] as String? ?? json['licenseState'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'first_Name': firstName,
        'last_Name': lastName,
        'email': email,
        'phone': phone,
        'employment_Type': employmentType,
        'cdl_License_Number': cdlLicenseNumber,
        'license_State': licenseState,
      };

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? employmentType,
    String? cdlLicenseNumber,
    String? licenseState,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      employmentType: employmentType ?? this.employmentType,
      cdlLicenseNumber: cdlLicenseNumber ?? this.cdlLicenseNumber,
      licenseState: licenseState ?? this.licenseState,
    );
  }
}
