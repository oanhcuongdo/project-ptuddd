class Course {
  final String id;
  final String code;
  final String name;
  final int credits;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    this.credits = 3,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      credits: json['credits'] as int? ?? 3,
    );
  }
}

class ProgramRegistration {
  final String id;
  final String userId;
  final String courseId;
  final String? courseName;
  final String? courseCode;
  final String role; // 'mentor' | 'mentee'
  final double? courseGrade;
  final String? strengthsOrNeeds;
  final int maxMentees;
  final List<int> availableSlots; // 0..20 (7 days x 3 sessions)

  const ProgramRegistration({
    required this.id,
    required this.userId,
    required this.courseId,
    this.courseName,
    this.courseCode,
    required this.role,
    this.courseGrade,
    this.strengthsOrNeeds,
    this.maxMentees = 5,
    this.availableSlots = const [],
  });

  factory ProgramRegistration.fromJson(Map<String, dynamic> json) {
    final course = json['ck_courses'] as Map<String, dynamic>?;
    return ProgramRegistration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      courseName: course?['name'] as String?,
      courseCode: course?['code'] as String?,
      role: json['role'] as String,
      courseGrade: (json['course_grade'] as num?)?.toDouble(),
      strengthsOrNeeds: json['strengths_or_needs'] as String?,
      maxMentees: json['max_mentees'] as int? ?? 5,
      availableSlots: (json['available_slots'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }

  static const List<String> dayLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  static const List<String> sessionLabels = ['Sáng', 'Chiều', 'Tối'];

  static String formatSlot(int index) {
    if (index < 0 || index >= 21) return '';
    final day = dayLabels[index ~/ 3];
    final session = sessionLabels[index % 3];
    return '$day ($session)';
  }
}

