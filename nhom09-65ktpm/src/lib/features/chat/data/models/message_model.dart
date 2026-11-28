/// Ánh xạ bảng `messages` trên Supabase Cloud cho Chat Realtime (1-1 & Nhóm).
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName = 'Thành viên',
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  MessageModel copyWith({
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content,
      createdAt: createdAt,
    );
  }

  factory MessageModel.fromMap(
    Map<String, dynamic> map, {
    String? senderName,
    String? senderAvatarUrl,
  }) {
    final resolvedName = (senderName ?? '').trim();
    return MessageModel(
      id: map['id'].toString(),
      conversationId: map['conversation_id'].toString(),
      senderId: map['sender_id'].toString(),
      senderName: resolvedName.isNotEmpty ? resolvedName : 'Thành viên',
      senderAvatarUrl: senderAvatarUrl,
      content: map['content'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
