/// Ánh xạ bảng `conversations` (thống nhất cả Chat 1-1 `'direct'` & Phòng học nhóm `'group'`)
class ConversationModel {
  final String id;
  final String type;
  final String name;
  final String description;
  final String topicCategory;
  final String level;
  final String targetLang;
  final int maxMembers;
  final String createdBy;
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
    this.topicCategory = '',
    this.level = 'A1',
    this.targetLang = 'en',
    this.maxMembers = 20,
    required this.createdBy,
    this.lastMessageText = '',
    this.lastMessageAt,
    this.memberCount = 0,
    this.isJoined = false,
    this.myRole,
  });

  bool get isGroup => type == 'group';
  bool get isFull => isGroup && memberCount >= maxMembers;

  factory ConversationModel.fromMap(
    Map<String, dynamic> map, {
    int memberCount = 0,
    bool isJoined = false,
    String? myRole,
    String? resolvedName,
  }) {
    final rawName = (map['name'] as String?)?.trim() ?? '';
    return ConversationModel(
      id: map['id'].toString(),
      type: map['type'] as String? ?? 'group',
      name: resolvedName ?? (rawName.isNotEmpty ? rawName : 'Phòng trò chuyện'),
      description: map['description'] as String? ?? '',
      topicCategory: map['topic_category'] as String? ?? '',
      level: map['level'] as String? ?? 'A1',
      targetLang: map['target_lang'] as String? ?? 'en',
      maxMembers: (map['max_members'] as num?)?.toInt() ?? 20,
      createdBy: map['created_by'].toString(),
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
