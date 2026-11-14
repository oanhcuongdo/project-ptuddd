import 'package:english_pronunciation_app/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 1); // crosses a month boundary below

  test('no practice gives zero streak', () {
    expect(computeStreak({}, today), (current: 0, best: 0));
  });

  test('consecutive days including today', () {
    final s = computeStreak({'2026-02-27', '2026-02-28', '2026-03-01'}, today);
    expect(s, (current: 3, best: 3));
  });

  test('streak survives until user practices today', () {
    final s = computeStreak({'2026-02-27', '2026-02-28'}, today);
    expect(s.current, 2);
  });

  test('gap breaks current streak but best is kept', () {
    final s = computeStreak(
        {'2026-02-01', '2026-02-02', '2026-02-03', '2026-02-04', '2026-02-27'}, today);
    expect(s, (current: 0, best: 4));
  });

  test('dayKey pads', () {
    expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
