import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'models/learning_event.dart';
import 'outbox.dart';

/// Ghi và đọc sự kiện học tập. Chủ sở hữu: **Phúc** (khung chung).
///
/// GHI (mọi tính năng): sau mỗi hoạt động gọi
/// ```dart
/// ref.read(progressServiceProvider).record(LearningEvent(
///   type: LearningEventType.pronunciationScored, xp: 2, durationSec: 40, score: 86, refId: '你好'));
/// ```
/// ĐỌC (trang chủ, thống kê, huy hiệu, bảng xếp hạng): `ref.watch(learningEventsProvider)`
/// rồi tính bằng [ProgressSummary], hoặc gọi API tổng hợp trên server.
abstract class ProgressService {
  /// Lưu sự kiện trên máy và đưa vào [Outbox] để gửi lên server.
  Future<void> record(LearningEvent event);

  /// Sự kiện đang có trên máy (mới nhất trước).
  List<LearningEvent> get events;

  /// Phát danh sách mới mỗi khi có thay đổi.
  Stream<List<LearningEvent>> get changes;

  /// Kéo sự kiện [days] ngày gần nhất từ server về (cần đăng nhập). Trả số sự kiện mới.
  Future<int> pullFromServer({int days = 90});

  /// Thêm sự kiện có sẵn (vd. dữ liệu giả từ menu dev). [sync] = có gửi lên server không.
  Future<void> addAll(Iterable<LearningEvent> events, {bool sync = false});

  /// Xoá sự kiện trên máy (không xoá trên server).
  void clearLocal();
}

final progressServiceProvider = Provider<ProgressService>((ref) {
  final s = LocalProgressService(ref.watch(outboxProvider), ref.watch(apiClientProvider));
  ref.onDispose(s.dispose);
  return s;
});

/// Danh sách sự kiện, tự cập nhật. Dùng trong widget: `ref.watch(learningEventsProvider)`.
final learningEventsProvider = StreamProvider<List<LearningEvent>>((ref) async* {
  final s = ref.watch(progressServiceProvider);
  yield s.events;
  yield* s.changes;
});

/// Lưu sự kiện trong RAM + gửi qua Outbox. Khi #23 xong, Đệ/Phúc chuyển phần
/// lưu trên máy sang SQLite (bảng `local_events`) mà không đổi interface.
class LocalProgressService implements ProgressService {
  final Outbox _outbox;
  final ApiClient _api;
  final _byId = <String, LearningEvent>{};
  final _changes = StreamController<List<LearningEvent>>.broadcast();

  LocalProgressService(this._outbox, this._api);

  @override
  List<LearningEvent> get events => _byId.values.toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Stream<List<LearningEvent>> get changes => _changes.stream;

  void _emit() => _changes.add(events);

  @override
  Future<void> record(LearningEvent event) async {
    _byId[event.id] = event;
    _emit();
    await _outbox.enqueue(OutboxItem(kind: 'event', id: event.id, payload: event.toJson()));
  }

  @override
  Future<void> addAll(Iterable<LearningEvent> events, {bool sync = false}) async {
    for (final e in events) {
      _byId[e.id] = e;
      if (sync) await _outbox.enqueue(OutboxItem(kind: 'event', id: e.id, payload: e.toJson()));
    }
    _emit();
  }

  @override
  Future<int> pullFromServer({int days = 90}) async {
    if ((await _api.storage.getToken()) == null) return 0;
    final since = DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();
    try {
      final list = await _api.get('/events?since=${Uri.encodeQueryComponent(since)}&limit=1000') as List;
      var added = 0;
      for (final j in list) {
        final e = LearningEvent.fromJson(j as Map<String, dynamic>);
        if (_byId.putIfAbsent(e.id, () => e) == e) added++;
      }
      if (added > 0) _emit();
      return added;
    } catch (e) {
      debugPrint('Progress: không kéo được sự kiện từ server ($e)');
      return 0;
    }
  }

  @override
  void clearLocal() {
    _byId.clear();
    _emit();
  }

  void dispose() => _changes.close();
}

/// Số liệu tổng hợp tính từ danh sách sự kiện (cùng quy tắc với server
/// `app/services/progress.py`): XP, streak, phút học mỗi ngày...
class ProgressSummary {
  final int xpTotal;
  final int currentStreak;
  final int longestStreak;

  /// Phút học theo ngày (khoá = ngày, giờ 00:00 theo máy).
  final Map<DateTime, int> minutesByDay;
  final Map<DateTime, int> xpByDay;
  final Map<LearningEventType, int> countByType;

  const ProgressSummary({
    required this.xpTotal,
    required this.currentStreak,
    required this.longestStreak,
    required this.minutesByDay,
    required this.xpByDay,
    required this.countByType,
  });

  int minutesOn(DateTime day) => minutesByDay[dateOnly(day)] ?? 0;

  static DateTime dateOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  factory ProgressSummary.from(Iterable<LearningEvent> events, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final seconds = <DateTime, int>{};
    final xp = <DateTime, int>{};
    final counts = <LearningEventType, int>{};
    var total = 0;
    for (final e in events) {
      final d = dateOnly(e.occurredAt);
      seconds[d] = (seconds[d] ?? 0) + e.durationSec;
      xp[d] = (xp[d] ?? 0) + e.xp;
      counts[e.type] = (counts[e.type] ?? 0) + 1;
      total += e.xp;
    }
    final days = seconds.keys.toList()..sort();
    var longest = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = prev != null && _daysBetween(prev, d) == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
      prev = d;
    }
    final current = days.isNotEmpty && _daysBetween(days.last, today) <= 1 ? run : 0;
    return ProgressSummary(
      xpTotal: total,
      currentStreak: current,
      longestStreak: longest,
      minutesByDay: {for (final e in seconds.entries) e.key: e.value ~/ 60},
      xpByDay: xp,
      countByType: counts,
    );
  }

  // Tính theo ngày lịch (UTC) để không lệch khi đổi giờ mùa hè.
  static int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}
