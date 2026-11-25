import 'package:english_pronunciation_app/data/active_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime clock;
  ActiveTimer make() => ActiveTimer(now: () => clock);
  setUp(() => clock = DateTime(2026, 11, 21, 20));

  test('thao tác liên tục: cộng đủ thời gian', () {
    final t = make();
    clock = clock.add(const Duration(seconds: 30));
    t.touch();
    clock = clock.add(const Duration(seconds: 20));
    expect(t.elapsedSeconds(), 50);
  });

  test('bỏ máy 20 phút chỉ tính tối đa 60 giây', () {
    final t = make();
    clock = clock.add(const Duration(minutes: 20));
    expect(t.elapsedSeconds(), 60);
  });

  test('nhiều khoảng nghỉ dài: mỗi khoảng bị chặn riêng', () {
    final t = make();
    for (var i = 0; i < 3; i++) {
      clock = clock.add(const Duration(minutes: 10));
      t.touch();
    }
    expect(t.elapsedSeconds(), 180);
  });

  test('đồng hồ bị chỉnh lùi không làm thời gian âm', () {
    final t = make();
    clock = clock.subtract(const Duration(minutes: 5));
    expect(t.elapsedSeconds(), 0);
  });
}
