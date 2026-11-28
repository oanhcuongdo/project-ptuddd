import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_tables.dart';
import '../../../../core/network/supabase_config.dart';
import '../models/notification_model.dart';

/// Repository quản lý Thông báo & kết nối WebSocket Realtime qua Supabase Realtime.
class NotificationRepository {
  bool get isReady => SupabaseConfig.isConfigured;

  /// Tải 30 thông báo gần nhất của người dùng từ bảng `notifications`
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final rows = await SupabaseConfig.client
        .from(DatabaseTables.notifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(30);

    return rows
        .map<NotificationModel>((row) => NotificationModel.fromMap(row))
        .toList();
  }

  /// Tạo một thông báo mới (tự động đẩy tức thì qua Supabase Realtime tới người nhận)
  Future<void> createNotification({
    required String userId,
    String? actorId,
    required String type,
    required String title,
    required String body,
    String? referenceId,
    bool isRead = false,
  }) async {
    if (!isReady) return;
    await SupabaseConfig.client.from(DatabaseTables.notifications).insert({
      'user_id': userId,
      'actor_id': actorId,
      'type': type,
      'title': title,
      'body': body,
      'reference_id': referenceId,
      'is_read': isRead,
    });
  }

  /// Xóa thông báo xin tham gia cũ của quản lý sau khi đã duyệt hoặc từ chối
  Future<void> deleteJoinRequestNotifications({
    required String ownerId,
    required String requesterId,
    required String conversationId,
  }) async {
    if (!isReady) return;
    await SupabaseConfig.client
        .from(DatabaseTables.notifications)
        .delete()
        .eq('user_id', ownerId)
        .eq('actor_id', requesterId)
        .eq('reference_id', conversationId)
        .eq('type', 'room_join_request');
  }

  /// Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    await SupabaseConfig.client
        .from(DatabaseTables.notifications)
        .update({'is_read': true}).eq('id', notificationId);
  }

  /// Đánh dấu toàn bộ thông báo của người dùng đã đọc
  Future<void> markAllAsRead(String userId) async {
    await SupabaseConfig.client
        .from(DatabaseTables.notifications)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Mở kênh WebSocket Supabase Realtime lắng nghe thông báo mới theo `user_id`
  RealtimeChannel? subscribeToUserNotifications({
    required String userId,
    required void Function(NotificationModel notification) onNewNotification,
  }) {
    if (!isReady) return null;

    final channel = SupabaseConfig.client.channel('notifications:$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: DatabaseTables.notifications,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isEmpty) return;
            onNewNotification(NotificationModel.fromMap(payload.newRecord));
          },
        )
        .subscribe();

    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    if (!isReady) return;
    await SupabaseConfig.client.removeChannel(channel);
  }
}
