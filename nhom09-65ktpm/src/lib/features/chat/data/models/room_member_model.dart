import 'conversation_model.dart';

/// Thông tin một thành viên chính thức trong phòng học (gồm vai trò Chủ phòng / Phó phòng / Thành viên).
class RoomMemberModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String proficiencyLevel;

  /// `'owner'` (Chủ phòng), `'co_owner'` (Phó phòng / Trợ giảng), hoặc `'member'` (Thành viên)
  final String role;
  final int streakCount;
  final DateTime? lastChatDate;
  final DateTime? joinedAt;

  const RoomMemberModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.proficiencyLevel = 'A1',
    this.role = 'member',
    this.streakCount = 0,
    this.lastChatDate,
    this.joinedAt,
  });

  bool get isOwner => role == 'owner';
  bool get isCoOwner => role == 'co_owner';
  bool get isMember => !isOwner && !isCoOwner;

  String get roleLabel {
    if (isOwner) return 'Chủ phòng';
    if (isCoOwner) return 'Trợ giảng';
    return 'Thành viên';
  }

  int get roleSortOrder {
    if (isOwner) return 0;
    if (isCoOwner) return 1;
    return 2;
  }

  /// Chuỗi lửa hiệu lực của thành viên này trong phòng (mất chuỗi nếu quên >= 2 ngày)
  int get effectiveStreak {
    if (streakCount <= 0 || lastChatDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastChatDate!.year, lastChatDate!.month, lastChatDate!.day);
    return today.difference(last).inDays <= 1 ? streakCount : 0;
  }

  RoomMemberModel copyWith({String? role}) {
    return RoomMemberModel(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      proficiencyLevel: proficiencyLevel,
      role: role ?? this.role,
      streakCount: streakCount,
      lastChatDate: lastChatDate,
      joinedAt: joinedAt,
    );
  }

  factory RoomMemberModel.fromRow(
    Map<String, dynamic> memberRow,
    Map<String, dynamic>? profileRow,
  ) {
    final rawName = (profileRow?['display_name'] as String?)?.trim() ?? '';
    return RoomMemberModel(
      userId: memberRow['user_id'].toString(),
      displayName: rawName.isNotEmpty ? rawName : 'Thành viên',
      avatarUrl: profileRow?['avatar_url'] as String?,
      proficiencyLevel:
          (profileRow?['proficiency_level'] as String? ?? 'A1').toUpperCase(),
      role: memberRow['role'] as String? ?? 'member',
      streakCount: (memberRow['streak_count'] as num?)?.toInt() ?? 0,
      lastChatDate: ConversationModel.parseDateOnly(memberRow['last_chat_date']),
      joinedAt: memberRow['joined_at'] != null
          ? DateTime.tryParse(memberRow['joined_at'].toString())
          : null,
    );
  }
}
