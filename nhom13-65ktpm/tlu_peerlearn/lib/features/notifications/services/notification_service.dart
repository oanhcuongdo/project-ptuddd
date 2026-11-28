import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final userNotificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
  return ref.watch(notificationServiceProvider).fetchNotifications(userId);
});

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static RealtimeChannel? _channel;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes local notifications and requests Android 13+ permission
  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localPlugin.initialize(settings: initSettings);

    final androidImpl = _localPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Shows a local notification on Android
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'tlu_peerlearn_channel',
      'TLU PeerLearn Thông báo',
      channelDescription: 'Thông báo phòng học, lời mời và lịch học',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Subscribes to realtime notifications for the current user
  void subscribeToUser(String userId, VoidCallback onNewNotification) {
    final client = _client;
    if (client == null) return;
    _channel?.unsubscribe();
    _channel = client
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            final title = record['title'] as String? ?? 'Thông báo mới';
            final body = record['body'] as String? ?? '';
            showLocalNotification(title: title, body: body);
            onNewNotification();
          },
        )
        .subscribe();
  }

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final client = _client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? roomId,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'room_id': ?roomId,
      });
    } catch (_) {}
  }

  Future<void> markAsRead(String notificationId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> markAllAsRead(String userId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }

  /// Checks upcoming sessions (within 30 mins) and notifies Mentee
  Future<void> checkUpcomingSessions(String userId) async {
    final client = _client;
    if (client == null) return;
    try {
      final now = DateTime.now();
      final soon = now.add(const Duration(minutes: 30));
      final memberRows = await client
          .from('room_members')
          .select('room_id')
          .eq('user_id', userId)
          .neq('role', 'mentor');
      final roomIds = (memberRows as List<dynamic>)
          .map((e) => e['room_id'] as String?)
          .whereType<String>()
          .toList();
      if (roomIds.isEmpty) return;

      final sessions = await client
          .from('tutoring_sessions')
          .select('id, title, scheduled_at, room_id')
          .inFilter('room_id', roomIds)
          .gte('scheduled_at', now.toIso8601String())
          .lte('scheduled_at', soon.toIso8601String());

      for (final s in sessions as List<dynamic>) {
        final title = s['title'] as String? ?? 'Buổi học sắp diễn ra';
        await showLocalNotification(
          title: 'Sắp đến giờ học!',
          body: 'Buổi học "$title" sắp bắt đầu trong vòng 30 phút tới.',
        );
      }
    } catch (_) {}
  }
}

