/// Ánh xạ bảng `conversations` (thống nhất cả Chat 1-1 `'direct'` & Phòng học nhóm `'group'`)
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
  final String createdBy;
  final String managerName;
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final int memberCount;
  final bool isJoined;
  final String? myRole;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.name,
    this.description = '',
    this.level,
    this.targetLang = 'en',
    this.maxMembers,
    required this.createdBy,
    this.managerName = '',
    this.lastMessageText = '',
    this.lastMessageAt,
    this.memberCount = 0,
    this.isJoined = false,
    this.myRole,
  });

  bool get isGroup => type == 'group';
  bool get isUnlimited => maxMembers == null;
  bool get hasLevelRequirement => level != null && level!.trim().isNotEmpty;
  bool get isFull =>
      isGroup && maxMembers != null && memberCount >= maxMembers!;

  String get levelLabel =>
      hasLevelRequirement ? level!.toUpperCase() : 'Mọi trình độ';

  String get memberSummary => maxMembers == null
      ? '$memberCount thành viên • Không giới hạn'
      : '$memberCount/$maxMembers thành viên';

  factory ConversationModel.fromMap(
    Map<String, dynamic> map, {
    int memberCount = 0,
    bool isJoined = false,
    String? myRole,
    String? resolvedName,
    String? managerName,
  }) {
    final rawName = (map['name'] as String?)?.trim() ?? '';
    final rawLevel = (map['level'] as String?)?.trim();
    return ConversationModel(
      id: map['id'].toString(),
      type: map['type'] as String? ?? 'group',
      name: resolvedName ?? (rawName.isNotEmpty ? rawName : 'Phòng trò chuyện'),
      description: map['description'] as String? ?? '',
      level: (rawLevel == null || rawLevel.isEmpty) ? null : rawLevel,
      targetLang: map['target_lang'] as String? ?? 'en',
      maxMembers: (map['max_members'] as num?)?.toInt(),
      createdBy: map['created_by'].toString(),
      managerName: managerName ?? '',
      lastMessageText: map['last_message_text'] as String? ?? '',
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.tryParse(map['last_message_at'].toString())
          : null,
      memberCount: memberCount,
      isJoined: isJoined,
      myRole: myRole,
    );
  }
}
