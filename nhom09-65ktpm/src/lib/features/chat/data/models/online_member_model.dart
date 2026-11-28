/// Thông tin tóm tắt thành viên cho bảng Xếp hạng chuỗi cao từ bảng `profiles`
/// kèm tên phòng học nơi thành viên đạt chuỗi cao nhất (`conversation_members`).
class OnlineMemberModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String targetLang;
  final String proficiencyLevel;
  final int streakCount;
  final int bestStreak;
  final String? topRoomName;

  const OnlineMemberModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.targetLang = 'en',
    this.proficiencyLevel = 'A1',
    this.streakCount = 0,
    this.bestStreak = 0,
    this.topRoomName,
  });

  factory OnlineMemberModel.fromMap(
    Map<String, dynamic> map, {
    int? resolvedStreakCount,
    int? resolvedBestStreak,
    String? topRoomName,
  }) {
    final rawName = (map['display_name'] as String?)?.trim() ?? '';
    final profileStreak = (map['streak_count'] as num?)?.toInt() ?? 0;
    final profileBest = (map['best_streak'] as num?)?.toInt() ?? 0;
    final cleanRoom = topRoomName?.trim();
    return OnlineMemberModel(
      userId: map['user_id'].toString(),
      displayName: rawName.isNotEmpty ? rawName : 'Thành viên',
      avatarUrl: map['avatar_url'] as String?,
      targetLang: (map['target_lang'] as String? ?? 'en').toUpperCase(),
      proficiencyLevel:
          (map['proficiency_level'] as String? ?? 'A1').toUpperCase(),
      streakCount: resolvedStreakCount ?? profileStreak,
      bestStreak: resolvedBestStreak ?? profileBest,
      topRoomName: (cleanRoom == null || cleanRoom.isEmpty) ? null : cleanRoom,
    );
  }
}
