/// Ánh xạ bảng `notifications` — thông báo Realtime dùng chung toàn hệ thống BuddyTalk
class NotificationModel {
  final String id;
  final String userId;
  final String? actorId;
  final String type;
  final String title;
  final String body;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.actorId,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isRoomJoinRequest => type == 'room_join_request';

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      actorId: actorId,
      type: type,
      title: title,
      body: body,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      actorId: map['actor_id']?.toString(),
      type: map['type'] as String? ?? 'system',
      title: map['title'] as String? ?? 'Thông báo',
      body: map['body'] as String? ?? '',
      referenceId: map['reference_id']?.toString(),
      isRead: map['is_read'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
