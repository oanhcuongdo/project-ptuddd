import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Quản lý trạng thái thông báo và kết nối WebSocket Realtime cho người dùng hiện tại.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  final NotificationRepository _repository;

  List<NotificationModel> _items = const [];
  bool _isLoading = false;
  String? _boundUserId;
  RealtimeChannel? _channel;
  void Function(NotificationModel notification)? _onRealtimeEvent;

  List<NotificationModel> get items => _items;
  bool get isLoading => _isLoading;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  /// Gắn phiên người dùng hiện tại: tải danh sách & mở kênh WebSocket Realtime
  void bindUser(
    String? userId, {
    void Function(NotificationModel notification)? onRealtimeEvent,
  }) {
    _onRealtimeEvent = onRealtimeEvent;
    if (userId == _boundUserId) return;

    _detachChannel();
    _boundUserId = userId;

    if (userId == null) {
      _items = const [];
      notifyListeners();
      return;
    }

    if (!_repository.isReady) return;

    refresh(userId);
    _channel = _repository.subscribeToUserNotifications(
      userId: userId,
      onNewNotification: _handleRealtimeInsert,
    );
  }

  void _handleRealtimeInsert(NotificationModel notification) {
    final alreadyExists = _items.any((n) => n.id == notification.id);
    if (alreadyExists) return;
    _items = [notification, ..._items];
    notifyListeners();
    _onRealtimeEvent?.call(notification);
  }

  Future<void> refresh([String? explicitUserId]) async {
    final uid = explicitUserId ?? _boundUserId;
    if (uid == null || !_repository.isReady) return;

    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.fetchNotifications(uid);
    } catch (e) {
      debugPrint('[NotificationProvider] Khong the tai thong bao: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    _items = _items
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();

    if (!_repository.isReady) return;
    try {
      await _repository.markAsRead(notificationId);
    } catch (e) {
      debugPrint('[NotificationProvider] Loi danh dau da doc: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _boundUserId;
    if (uid == null) return;

    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    if (!_repository.isReady) return;
    try {
      await _repository.markAllAsRead(uid);
    } catch (e) {
      debugPrint('[NotificationProvider] Loi danh dau doc tat ca: $e');
    }
  }

  void _detachChannel() {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      _repository.unsubscribe(ch);
    }
  }

  @override
  void dispose() {
    _detachChannel();
    super.dispose();
  }
}
