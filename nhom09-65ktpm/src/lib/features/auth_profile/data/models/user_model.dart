/// Ánh xạ bảng `users` (001_auth_and_users.sql)
class UserModel {
  final String id;
  final String status;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.status = 'active',
    this.role = 'user',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'].toString(),
      status: map['status'] as String? ?? 'active',
      role: map['role'] as String? ?? 'user',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
