/// Ánh xạ bảng `room_meet_sessions` — buổi học Video Call Jitsi Meet do Chủ phòng / Trợ giảng tạo.
class MeetSessionModel {
  final String id;
  final String conversationId;
  final String hostId;
  final String hostName;
  final String title;
  final String meetRoomCode;
  final DateTime scheduledAt;
  final int minMinutes;

  /// `'scheduled'` (đã hẹn lịch), `'live'` (đang diễn ra), `'ended'` (đã kết thúc)
  final String status;
  final DateTime createdAt;

  const MeetSessionModel({
    required this.id,
    required this.conversationId,
    required this.hostId,
    this.hostName = 'Trợ giảng',
    required this.title,
    required this.meetRoomCode,
    required this.scheduledAt,
    this.minMinutes = 15,
    this.status = 'live',
    required this.createdAt,
  });

  bool get isLive => status == 'live';
  bool get isScheduled => status == 'scheduled';
  bool get isEnded => status == 'ended';
  int get requiredSeconds => minMinutes * 60;

  /// Danh sách máy chủ Video Call công khai miễn phí cho phép nhúng iframe trực tiếp
  /// (không bị chặn X-Frame-Options và không bắt đăng nhập Moderator)
  static const List<({String id, String label})> meetServers = [
    (id: 'jitsi_riot', label: 'Jitsi Meet'),
    (id: 'mirotalk', label: 'MiroTalk SFU'),
    (id: 'jitsi_guifi', label: 'Jitsi Dự phòng'),
  ];

  /// Đường dẫn phòng Video Call theo máy chủ đang chọn
  String buildMeetUrl(String displayName, {String serverId = 'jitsi_riot'}) {
    final safeName = Uri.encodeComponent(
      displayName.trim().isNotEmpty ? displayName.trim() : 'BuddyTalk Learner',
    );
    switch (serverId) {
      case 'mirotalk':
        return 'https://sfu.mirotalk.com/join?room=$meetRoomCode&name=$safeName&audio=1&video=1&notify=0';
      case 'jitsi_guifi':
        return 'https://meet.guifi.net/$meetRoomCode'
            '#userInfo.displayName="$safeName"'
            '&config.prejoinPageEnabled=false'
            '&config.disableDeepLinking=true';
      case 'jitsi_riot':
      default:
        return 'https://jitsi.riot.im/$meetRoomCode'
            '#userInfo.displayName="$safeName"'
            '&config.prejoinPageEnabled=false'
            '&config.disableDeepLinking=true';
    }
  }

  MeetSessionModel copyWith({String? status}) {
    return MeetSessionModel(
      id: id,
      conversationId: conversationId,
      hostId: hostId,
      hostName: hostName,
      title: title,
      meetRoomCode: meetRoomCode,
      scheduledAt: scheduledAt,
      minMinutes: minMinutes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory MeetSessionModel.fromMap(
    Map<String, dynamic> map, {
    String? hostName,
  }) {
    final resolvedHost = (hostName ?? '').trim();
    return MeetSessionModel(
      id: map['id'].toString(),
      conversationId: map['conversation_id'].toString(),
      hostId: map['host_id'].toString(),
      hostName: resolvedHost.isNotEmpty ? resolvedHost : 'Trợ giảng',
      title: (map['title'] as String?)?.trim() ?? 'Buổi luyện nói Video Call',
      meetRoomCode: (map['meet_room_code'] as String?)?.trim() ?? 'BuddyTalkRoom',
      scheduledAt: map['scheduled_at'] != null
          ? (DateTime.tryParse(map['scheduled_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      minMinutes: (map['min_minutes'] as num?)?.toInt() ?? 15,
      status: map['status'] as String? ?? 'live',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Ánh xạ bảng `room_meet_attendance` — theo dõi thời gian học thực tế & trạng thái lên chuỗi từng người.
class MeetAttendanceModel {
  final String sessionId;
  final String userId;
  final String displayName;
  final int attendedSeconds;
  final bool streakAwarded;
  final DateTime updatedAt;

  const MeetAttendanceModel({
    required this.sessionId,
    required this.userId,
    this.displayName = 'Thành viên',
    this.attendedSeconds = 0,
    this.streakAwarded = false,
    required this.updatedAt,
  });

  int get attendedMinutes => attendedSeconds ~/ 60;

  factory MeetAttendanceModel.fromRow(
    Map<String, dynamic> map, {
    String? displayName,
  }) {
    final resolvedName = (displayName ?? '').trim();
    return MeetAttendanceModel(
      sessionId: map['session_id'].toString(),
      userId: map['user_id'].toString(),
      displayName: resolvedName.isNotEmpty ? resolvedName : 'Thành viên',
      attendedSeconds: (map['attended_seconds'] as num?)?.toInt() ?? 0,
      streakAwarded: map['streak_awarded'] as bool? ?? false,
      updatedAt: map['updated_at'] != null
          ? (DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
