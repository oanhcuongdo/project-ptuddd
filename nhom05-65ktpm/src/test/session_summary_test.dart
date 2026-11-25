import 'package:english_pronunciation_app/data/lessons.dart';
import 'package:english_pronunciation_app/data/session_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phiên trống: 0 lượt, trung bình 0, chưa có mục mới thành thạo', () {
    final s = SessionSummary();
    expect((s.attempts, s.average), (0, 0));
    expect(s.newlyMastered, isEmpty);
  });

  test('đếm lượt và tính điểm trung bình', () {
    final s = SessionSummary()
      ..add('think', 60, 0)
      ..add('three', 80, 0)
      ..add('think', 100, 0);
    expect(s.attempts, 3);
    expect(s.average, closeTo(80, 1e-9));
  });

  test('mục vượt ngưỡng lần đầu trong phiên được tính là mới thành thạo', () {
    final s = SessionSummary()..add('think', masteryScore, masteryScore - 1);
    expect(s.newlyMastered, {'think'});
  });

  test('mục đã thành thạo từ trước phiên không tính là mới', () {
    final s = SessionSummary()..add('think', 100, masteryScore);
    expect(s.newlyMastered, isEmpty);
  });

  test('chưa đạt ngưỡng thì chưa tính; lặp lại cùng mục chỉ tính một lần', () {
    final s = SessionSummary()
      ..add('think', masteryScore - 1, 0)
      ..add('think', masteryScore, 0)
      ..add('think', 100, 0);
    expect(s.newlyMastered, {'think'});
  });
}
