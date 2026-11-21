class TutoringSession {
  final String id;
  final String roomId;
  final String mentorId;
  final String title;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String mode; // 'offline' | 'online'
  final String? locationOrLink;
  final String? plannedContent;
  final int? actualDurationMinutes;
  final String? guidedContent;
  final String? outcomes;
  final String? issues;
  final String status; // 'scheduled' | 'completed' | 'cancelled'
  final DateTime createdAt;
  final String? mentorName;

  const TutoringSession({
    required this.id,
    required this.roomId,
    required this.mentorId,
    required this.title,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.mode,
    this.locationOrLink,
    this.plannedContent,
    this.actualDurationMinutes,
    this.guidedContent,
    this.outcomes,
    this.issues,
    this.status = 'scheduled',
    required this.createdAt,
    this.mentorName,
  });

  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  bool get isCancelled => status == 'cancelled';
  bool get isOnline => mode == 'online';

  factory TutoringSession.fromJson(Map<String, dynamic> json) {
    return TutoringSession(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      mentorId: json['mentor_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.parse(json['scheduled_start'] as String)
          : DateTime.now(),
      scheduledEnd: json['scheduled_end'] != null
          ? DateTime.parse(json['scheduled_end'] as String)
          : DateTime.now(),
      mode: json['mode'] as String? ?? 'offline',
      locationOrLink: json['location_or_link'] as String?,
      plannedContent: json['planned_content'] as String?,
      actualDurationMinutes: (json['actual_duration_minutes'] as num?)?.toInt(),
      guidedContent: json['guided_content'] as String?,
      outcomes: json['outcomes'] as String?,
      issues: json['issues'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      mentorName: json['ck_profiles'] != null
          ? (json['ck_profiles'] as Map<String, dynamic>)['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'mentor_id': mentorId,
      'title': title,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'mode': mode,
      'location_or_link': locationOrLink,
      'planned_content': plannedContent,
      'actual_duration_minutes': actualDurationMinutes,
      'guided_content': guidedContent,
      'outcomes': outcomes,
      'issues': issues,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TutoringSession copyWith({
    String? status,
    int? actualDurationMinutes,
    String? guidedContent,
    String? outcomes,
    String? issues,
  }) {
    return TutoringSession(
      id: id,
      roomId: roomId,
      mentorId: mentorId,
      title: title,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      mode: mode,
      locationOrLink: locationOrLink,
      plannedContent: plannedContent,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      guidedContent: guidedContent ?? this.guidedContent,
      outcomes: outcomes ?? this.outcomes,
      issues: issues ?? this.issues,
      status: status ?? this.status,
      createdAt: createdAt,
      mentorName: mentorName,
    );
  }
}

class SessionAttendance {
  final String id;
  final String sessionId;
  final String menteeId;
  final String? menteeName;
  final String mentorMarkedStatus; // 'present' | 'absent'
  final bool menteeConfirmed; // BR-09, BR-10
  final DateTime? menteeConfirmedAt;

  const SessionAttendance({
    required this.id,
    required this.sessionId,
    required this.menteeId,
    this.menteeName,
    this.mentorMarkedStatus = 'absent',
    this.menteeConfirmed = false,
    this.menteeConfirmedAt,
  });

  bool get isPresent => mentorMarkedStatus == 'present';

  factory SessionAttendance.fromJson(Map<String, dynamic> json) {
    return SessionAttendance(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      menteeId: json['mentee_id'] as String? ?? '',
      menteeName: json['ck_profiles'] != null
          ? (json['ck_profiles'] as Map<String, dynamic>)['full_name'] as String?
          : null,
      mentorMarkedStatus: json['mentor_marked_status'] as String? ?? 'absent',
      menteeConfirmed: json['mentee_confirmed'] as bool? ?? false,
      menteeConfirmedAt: json['mentee_confirmed_at'] != null
          ? DateTime.parse(json['mentee_confirmed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'mentee_id': menteeId,
      'mentor_marked_status': mentorMarkedStatus,
      'mentee_confirmed': menteeConfirmed,
      'mentee_confirmed_at': menteeConfirmedAt?.toIso8601String(),
    };
  }

  SessionAttendance copyWith({
    String? mentorMarkedStatus,
    bool? menteeConfirmed,
    DateTime? menteeConfirmedAt,
  }) {
    return SessionAttendance(
      id: id,
      sessionId: sessionId,
      menteeId: menteeId,
      menteeName: menteeName,
      mentorMarkedStatus: mentorMarkedStatus ?? this.mentorMarkedStatus,
      menteeConfirmed: menteeConfirmed ?? this.menteeConfirmed,
      menteeConfirmedAt: menteeConfirmedAt ?? this.menteeConfirmedAt,
    );
  }
}

class SessionEvidence {
  final String id;
  final String sessionId;
  final String imageUrl;
  final String? caption;
  final DateTime uploadedAt;

  const SessionEvidence({
    required this.id,
    required this.sessionId,
    required this.imageUrl,
    this.caption,
    required this.uploadedAt,
  });

  factory SessionEvidence.fromJson(Map<String, dynamic> json) {
    return SessionEvidence(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      caption: json['caption'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'image_url': imageUrl,
      'caption': caption,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
