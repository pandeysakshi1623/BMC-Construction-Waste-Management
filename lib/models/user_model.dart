class UserModel {
  final String id;
  final String email;
  final String role; // 'contractor', 'citizen', 'driver', 'bmc'
  final String token;
  final String contractorId; // populated for contractor/driver roles

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
    this.contractorId = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'] ?? '',
      contractorId: json['contractor_id'] ?? '',
    );
  }
}
