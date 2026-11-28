/// Giới hạn tần suất phía client: tối đa [maxCalls] lần trong [window].
///
/// Dùng "cửa sổ trượt": lưu thời điểm các lần gọi gần đây, bỏ những lần
/// đã quá [window]. Dart thuần, có thể truyền [clock] giả khi test.
class RateLimiter {
  RateLimiter({
    required this.maxCalls,
    this.window = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxCalls;
  final Duration window;
  final DateTime Function() _clock;
  final List<DateTime> _calls = [];

  /// Trả về true và ghi nhận một lần gọi nếu còn lượt; false nếu đã vượt.
  bool tryAcquire() {
    final now = _clock();
    _calls.removeWhere((t) => now.difference(t) >= window);
    if (_calls.length >= maxCalls) return false;
    _calls.add(now);
    return true;
  }
}
