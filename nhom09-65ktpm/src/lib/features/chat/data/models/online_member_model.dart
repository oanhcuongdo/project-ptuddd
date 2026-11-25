/// Thông tin tóm tắt thành viên đang trực tuyến từ bảng `profiles` (`is_online = true`).
class OnlineMemberModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String targetLang;
  final String proficiencyLevel;

  const OnlineMemberModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.targetLang = 'en',
    this.proficiencyLevel = 'A1',
  });

  factory OnlineMemberModel.fromMap(Map<String, dynamic> map) {
    final rawName = (map['display_name'] as String?)?.trim() ?? '';
    return OnlineMemberModel(
      userId: map['user_id'].toString(),
      displayName: rawName.isNotEmpty ? rawName : 'Thành viên',
      avatarUrl: map['avatar_url'] as String?,
      targetLang: (map['target_lang'] as String? ?? 'en').toUpperCase(),
      proficiencyLevel:
          (map['proficiency_level'] as String? ?? 'A1').toUpperCase(),
    );
  }
}
