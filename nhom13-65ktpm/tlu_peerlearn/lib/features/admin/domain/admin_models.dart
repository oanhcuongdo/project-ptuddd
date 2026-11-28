class AdminOverviewStats {
  final int totalMentors;
  final int totalMentees;
  final int totalRooms;
  final int activeRooms;
  final int totalSessions;
  final int completedSessions;

  const AdminOverviewStats({
    this.totalMentors = 0,
    this.totalMentees = 0,
    this.totalRooms = 0,
    this.activeRooms = 0,
    this.totalSessions = 0,
    this.completedSessions = 0,
  });
}

class AdminRoomSummary {
  final String id;
  final String name;
  final String roomCode;
  final String courseName;
  final String mentorName;
  final bool isOpen;

  const AdminRoomSummary({
    required this.id,
    required this.name,
    required this.roomCode,
    required this.courseName,
    required this.mentorName,
    this.isOpen = true,
  });

  factory AdminRoomSummary.fromJson(Map<String, dynamic> json) {
    final course = json['ck_courses'] as Map<String, dynamic>?;
    final mentor = json['ck_profiles'] as Map<String, dynamic>?;
    return AdminRoomSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      roomCode: json['room_code'] as String? ?? '',
      courseName: course?['name'] as String? ?? 'Chưa rõ học phần',
      mentorName: mentor?['full_name'] as String? ?? 'Chưa rõ Mentor',
      isOpen: json['is_open'] as bool? ?? true,
    );
  }
}

class AdminSessionAttendance {
  final String menteeName;
  final String mentorMarkedStatus; // 'present' | 'absent'
  final bool menteeConfirmed;

  const AdminSessionAttendance({
    required this.menteeName,
    required this.mentorMarkedStatus,
    required this.menteeConfirmed,
  });

  factory AdminSessionAttendance.fromJson(Map<String, dynamic> json) {
    final profile = json['ck_profiles'] as Map<String, dynamic>?;
    return AdminSessionAttendance(
      menteeName: profile?['full_name'] as String? ?? 'Sinh viên',
      mentorMarkedStatus: json['mentor_marked_status'] as String? ?? 'absent',
      menteeConfirmed: json['mentee_confirmed'] as bool? ?? false,
    );
  }
}

class AdminSessionLog {
  final String id;
  final String title;
  final String roomName;
  final String mentorName;
  final DateTime scheduledStart;
  final String? guidedContent;
  final String status;
  final List<AdminSessionAttendance> attendances;
  final List<String> evidenceUrls;

  const AdminSessionLog({
    required this.id,
    required this.title,
    required this.roomName,
    required this.mentorName,
    required this.scheduledStart,
    this.guidedContent,
    this.status = 'completed',
    this.attendances = const [],
    this.evidenceUrls = const [],
  });

  factory AdminSessionLog.fromJson(Map<String, dynamic> json) {
    final room = json['ck_study_rooms'] as Map<String, dynamic>?;
    final mentor = json['ck_profiles'] as Map<String, dynamic>?;
    final rawAttendances = json['ck_session_attendances'] as List<dynamic>? ?? [];
    final rawEvidences = json['ck_session_evidences'] as List<dynamic>? ?? [];

    return AdminSessionLog(
      id: json['id'] as String,
      title: json['title'] as String,
      roomName: room?['name'] as String? ?? 'Phòng học',
      mentorName: mentor?['full_name'] as String? ?? 'Mentor',
      scheduledStart: DateTime.tryParse(
              json['scheduled_start'] as String? ?? '') ??
          DateTime.now(),
      guidedContent: json['guided_content'] as String?,
      status: json['status'] as String? ?? 'completed',
      attendances: rawAttendances
          .map((e) =>
              AdminSessionAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
      evidenceUrls: rawEvidences
          .map((e) => (e as Map<String, dynamic>)['image_url'] as String? ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }
}
