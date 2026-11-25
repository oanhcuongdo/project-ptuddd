/// Ánh xạ bảng `conversations` (thống nhất cả Chat 1-1 `'direct'` & Phòng học nhóm `'group'`)
/// kèm chuỗi lửa riêng của người dùng trong phòng (kiểu TikTok Streak).
class ConversationModel {
  final String id;
  final String type;
  final String name;
  final String description;

  /// `null` nghĩa là phòng không yêu cầu trình độ (mọi trình độ đều tham gia được)
  final String? level;
  final String targetLang;

  /// `null` nghĩa là phòng không giới hạn số lượng thành viên
  final int? maxMembers;

  /// `true` => Cần người quản lý duyệt mới được vào phòng; `false` => Vào trực tiếp
  final bool requireApproval;

  /// Link ảnh bìa (https://...) hoặc mã màu nền có sẵn (`preset:teal`, `preset:ocean`...)
  final String? coverUrl;

  /// Định hướng dài hạn của CLB (VD: Giao tiếp tự do, IELTS / Chứng chỉ, Phát âm...)
  final String? roomFocus;

  final String createdBy;
  final String managerName;
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final int memberCount;
  final int pendingCount;
  final bool isJoined;

  /// `'approved'`, `'pending'`, hoặc `null` nếu chưa gửi yêu cầu
  final String? membershipStatus;
  final String? myRole;

  /// Chuỗi lửa riêng của người dùng hiện tại trong phòng này (`conversation_members`)
  final int roomStreakCount;
  final int bestStreak;
  final DateTime? lastChatDate;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.name,
    this.description = '',
    this.level,
    this.targetLang = 'en',
    this.maxMembers,
    this.requireApproval = false,
    this.coverUrl,
    this.roomFocus,
    required this.createdBy,
    this.managerName = '',
    this.lastMessageText = '',
    this.lastMessageAt,
    this.memberCount = 0,
    this.pendingCount = 0,
    this.isJoined = false,
    this.membershipStatus,
    this.myRole,
    this.roomStreakCount = 0,
    this.bestStreak = 0,
    this.lastChatDate,
  });

  bool get isGroup => type == 'group';
  bool get isUnlimited => maxMembers == null;
  bool get isOwner => myRole == 'owner';
  bool get isPending => membershipStatus == 'pending';
  bool get hasLevelRequirement => level != null && level!.trim().isNotEmpty;
  bool get isFull =>
      isGroup && maxMembers != null && memberCount >= maxMembers!;

  String get levelLabel =>
      hasLevelRequirement ? level!.toUpperCase() : 'Mọi trình độ';

  String get memberSummary => maxMembers == null
      ? '$memberCount thành viên • Không giới hạn'
      : '$memberCount/$maxMembers thành viên';

  static DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  int _daysSinceLastChat([DateTime? now]) {
    if (lastChatDate == null) return 9999;
    final ref = _dayOnly(now ?? DateTime.now());
    final last = _dayOnly(lastChatDate!);
    return ref.difference(last).inDays;
  }

  /// Chuỗi lửa thực tế hiển thị (giống TikTok):
  /// - Nhắn hôm nay hoặc hôm qua -> giữ nguyên chuỗi
  /// - Quên từ 1 ngày trọn vẹn trở lên (chênh >= 2 ngày) -> tự mất chuỗi về 0
  int effectiveRoomStreak([DateTime? now]) {
    if (roomStreakCount <= 0 || lastChatDate == null) return 0;
    final diff = _daysSinceLastChat(now);
    return diff <= 1 ? roomStreakCount : 0;
  }

  /// Đã nhắn ít nhất 1 tin hôm nay trong phòng này (đốm lửa sáng rực)
  bool isStreakLitToday([DateTime? now]) =>
      roomStreakCount > 0 && _daysSinceLastChat(now) == 0;

  /// Hôm qua có nhắn nhưng hôm nay chưa nhắn -> cảnh báo sắp mất chuỗi
  bool isStreakAtRisk([DateTime? now]) =>
      roomStreakCount > 0 && _daysSinceLastChat(now) == 1;

  /// Đã từng có chuỗi trước đó nhưng quên > 1 ngày nên bị mất chuỗi
  bool isStreakLost([DateTime? now]) =>
      roomStreakCount > 0 && _daysSinceLastChat(now) >= 2;

  ConversationModel copyWith({
    int? roomStreakCount,
    int? bestStreak,
    DateTime? lastChatDate,
    String? lastMessageText,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      id: id,
      type: type,
      name: name,
      description: description,
      level: level,
      targetLang: targetLang,
      maxMembers: maxMembers,
      requireApproval: requireApproval,
      coverUrl: coverUrl,
      roomFocus: roomFocus,
      createdBy: createdBy,
      managerName: managerName,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      memberCount: memberCount,
      pendingCount: pendingCount,
      isJoined: isJoined,
      membershipStatus: membershipStatus,
      myRole: myRole,
      roomStreakCount: roomStreakCount ?? this.roomStreakCount,
      bestStreak: bestStreak ?? this.bestStreak,
      lastChatDate: lastChatDate ?? this.lastChatDate,
    );
  }

  static DateTime? parseDateOnly(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    final datePart = str.split('T').first.split(' ').first;
    final parts = datePart.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.tryParse(str);
    return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
  }

  factory ConversationModel.fromMap(
    Map<String, dynamic> map, {
    int memberCount = 0,
    int pendingCount = 0,
    bool isJoined = false,
    String? membershipStatus,
    String? myRole,
    String? resolvedName,
    String? managerName,
    int roomStreakCount = 0,
    int bestStreak = 0,
    DateTime? lastChatDate,
  }) {
    final rawName = (map['name'] as String?)?.trim() ?? '';
    final rawLevel = (map['level'] as String?)?.trim();
    final rawCover = (map['cover_url'] as String?)?.trim();
    final rawFocus = (map['room_focus'] as String?)?.trim();
    return ConversationModel(
      id: map['id'].toString(),
      type: map['type'] as String? ?? 'group',
      name: resolvedName ?? (rawName.isNotEmpty ? rawName : 'Phòng trò chuyện'),
      description: map['description'] as String? ?? '',
      level: (rawLevel == null || rawLevel.isEmpty) ? null : rawLevel,
      targetLang: map['target_lang'] as String? ?? 'en',
      maxMembers: (map['max_members'] as num?)?.toInt(),
      requireApproval: map['require_approval'] as bool? ?? false,
      coverUrl: (rawCover == null || rawCover.isEmpty) ? null : rawCover,
      roomFocus: (rawFocus == null || rawFocus.isEmpty) ? null : rawFocus,
      createdBy: map['created_by'].toString(),
      managerName: managerName ?? '',
      lastMessageText: map['last_message_text'] as String? ?? '',
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.tryParse(map['last_message_at'].toString())
          : null,
      memberCount: memberCount,
      pendingCount: pendingCount,
      isJoined: isJoined,
      membershipStatus: membershipStatus,
      myRole: myRole,
      roomStreakCount: roomStreakCount,
      bestStreak: bestStreak,
      lastChatDate: lastChatDate,
    );
  }
}
