/// Đếm thời gian học thật. Mỗi lần người học thao tác ([touch]), cộng khoảng
/// thời gian kể từ lần trước nhưng tối đa [idleCap], nên để màn hình mở mà
/// không làm gì (hoặc app chạy nền) không bị tính là đang học.
class ActiveTimer {
  final Duration idleCap;
  final DateTime Function() _now;
  Duration _total = Duration.zero;
  late DateTime _last;

  ActiveTimer({this.idleCap = const Duration(seconds: 60), DateTime Function()? now})
      : _now = now ?? DateTime.now {
    _last = _now();
  }

  void touch() {
    final t = _now();
    final gap = t.difference(_last);
    if (gap > Duration.zero) _total += gap > idleCap ? idleCap : gap;
    _last = t;
  }

  /// Tổng số giây học đã tích lũy tới thời điểm hiện tại.
  int elapsedSeconds() {
    touch();
    return _total.inSeconds;
  }
}
