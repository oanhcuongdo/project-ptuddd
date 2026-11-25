class UserModel {
  final int? id;
  final String name;
  final String email;
  final String studentId;
  final String className;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.studentId = '2351170602',
    this.className = '65KTPM',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'student_id': studentId,
      'class_name': className,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['student_id'] ?? '',
      className: map['class_name'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
