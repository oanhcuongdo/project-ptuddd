class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? studentId;
  final String? faculty;
  final String? className;
  final String? phone;
  final String? avatarUrl;
  final String role; // 'student' | 'admin'

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.studentId,
    this.faculty,
    this.className,
    this.phone,
    this.avatarUrl,
    this.role = 'student',
  });

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      studentId: json['student_id'] as String?,
      faculty: json['faculty'] as String?,
      className: json['class_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'student_id': studentId,
      'faculty': faculty,
      'class_name': className,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }
}

