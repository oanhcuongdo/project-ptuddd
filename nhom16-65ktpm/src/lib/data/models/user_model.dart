/// Model người dùng và phân quyền cho GoodDeeds Fund
/// Phụ trách: Nguyễn Văn Huỳnh (Nhóm trưởng)
class UserModel {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final String role; // 'admin' hoặc 'member'
  final String? avatar;
  final String? password;

  const UserModel({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.role,
    this.avatar,
    this.password,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'studentId': studentId,
      'email': email,
      'role': role,
      'avatar': avatar,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      studentId: map['studentId'] as String,
      email: map['email'] as String,
      role: map['role'] as String? ?? 'member',
      avatar: map['avatar'] as String?,
      password: map['password'] as String?,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? studentId,
    String? email,
    String? role,
    String? avatar,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      password: password ?? this.password,
    );
  }
}
