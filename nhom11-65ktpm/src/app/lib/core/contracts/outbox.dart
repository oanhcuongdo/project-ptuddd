import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'fake_implementation.dart';
import 'models/learning_event.dart';

/// Một thay đổi cần gửi lên server.
///
/// [kind] quyết định gửi tới đâu (bản thật của Đệ ánh xạ kind → endpoint):
/// - `event` → `POST /api/events` (payload = `LearningEvent.toJson()`)
/// - các kind khác do chủ tính năng thêm, vd. `srs_card`, `writing_attempt`
///   (→ `POST /api/sync/push` ở #25).
class OutboxItem {
  final String id;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int attempts;

  OutboxItem({required this.kind, required this.payload, String? id, DateTime? createdAt, this.attempts = 0})
    : id = id ?? newUuid(),
      createdAt = createdAt ?? DateTime.now();
}

/// Hàng đợi đồng bộ offline-first. Chủ sở hữu: **Đệ** (#23 SQLite, #25 sync).
///
/// Tính năng nào cũng chỉ `enqueue()`; không gọi thẳng API ghi dữ liệu học tập.
/// Mất mạng thì item nằm lại trong hàng đợi và được gửi khi [flush] lần sau.
abstract class Outbox {
  Future<void> enqueue(OutboxItem item);

  /// Gửi những gì đang chờ. Không ném lỗi: lỗi mạng thì giữ lại để thử sau.
  Future<void> flush();

  Future<int> pendingCount();

  /// Phát mỗi khi số item chờ thay đổi (menu dev, biểu tượng "chưa đồng bộ").
  Stream<int> get pendingChanges;
}

final outboxProvider = Provider<Outbox>((ref) {
  final o = MemoryOutbox(ref.watch(apiClientProvider));
  ref.onDispose(o.dispose);
  return o;
});

/// Bản giả: giữ hàng đợi trong RAM (mất khi tắt app), gửi ngay khi enqueue.
/// Chưa có retry/backoff, chưa sống sót qua khởi động lại: phần đó là của #25.
class MemoryOutbox with FakeImplementation implements Outbox {
  final ApiClient _api;
  final _items = <OutboxItem>[];
  final _changes = StreamController<int>.broadcast();
  Future<void>? _running;

  MemoryOutbox(this._api);

  @override
  Stream<int> get pendingChanges => _changes.stream;

  @override
  Future<int> pendingCount() async => _items.length;

  @override
  Future<void> enqueue(OutboxItem item) async {
    _items.add(item);
    _changes.add(_items.length);
    unawaited(flush());
  }

  @override
  Future<void> flush() => _running ??= _flush().whenComplete(() => _running = null);

  Future<void> _flush() async {
    final events = _items.where((i) => i.kind == 'event').toList();
    if (events.isEmpty) return;
    // Chưa đăng nhập thì giữ lại, đăng nhập xong sẽ gửi.
    if ((await _api.storage.getToken()) == null) return;
    try {
      for (var i = 0; i < events.length; i += 200) {
        final batch = events.skip(i).take(200).toList();
        await _api.post('/events', body: {'events': [for (final e in batch) e.payload]});
        _items.removeWhere(batch.contains);
        _changes.add(_items.length);
      }
    } catch (e) {
      for (final item in events) {
        item.attempts++;
      }
      debugPrint('Outbox: chưa gửi được ${events.length} sự kiện, sẽ thử lại ($e)');
    }
  }

  void dispose() => _changes.close();
}
