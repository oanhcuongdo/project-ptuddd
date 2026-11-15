import 'package:english_pronunciation_app/scoring/rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no rate before the minimum attempts', () {
    expect(computeRate(List.filled(minAttemptsForRate - 1, 90)), isNull);
  });

  test('averages only the latest window', () {
    // 20 recent scores of 80, then old scores of 0 that must be ignored.
    final r = computeRate([...List.filled(rateWindow, 80), ...List.filled(30, 0)])!;
    expect(r.value, 80);
    expect(r.attempts, rateWindow);
    expect(r.level, Level.intermediate);
  });

  test('level boundaries', () {
    expect(Level.of(0), Level.beginner);
    expect(Level.of(49.9), Level.beginner);
    expect(Level.of(50), Level.elementary);
    expect(Level.of(69.9), Level.elementary);
    expect(Level.of(70), Level.intermediate);
    expect(Level.of(85), Level.advanced);
    expect(Level.of(100), Level.advanced);
  });
}
