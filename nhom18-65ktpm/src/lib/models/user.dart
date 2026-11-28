/// Hồ sơ người dùng, tương ứng bảng `public.users`.
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.fcmToken,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;

  /// rider | owner | volunteer | admin
  final String role;

  /// active | banned
  final String status;
  final String? fcmToken;
  final DateTime? createdAt;

  bool get isBanned => status == 'banned';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'].toString(),
      fullName: map['full_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'rider',
      status: map['status']?.toString() ?? 'active',
      fcmToken: map['fcm_token']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'fcm_token': fcmToken,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
