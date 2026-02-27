class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String kycStatus;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.kycStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      gender: json['gender'] ?? '',
      kycStatus: json['kycStatus'] ?? 'PENDING',
    );
  }
}
