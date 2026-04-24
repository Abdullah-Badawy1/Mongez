class UserModel {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String address;
  final String role;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        role: json['role'] as String? ?? 'client',
      );

  bool get isWorker => role == 'worker';
  bool get isClient => role == 'client';
}
