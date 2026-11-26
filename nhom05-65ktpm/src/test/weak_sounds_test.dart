import 'package:english_pronunciation_app/scoring/weak_sounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('xếp theo tỉ lệ sai, không theo số lần sai thô', () {
    // TH: 20 lần gặp, 5 lần sai (25%). L: 4 lần gặp, 3 lần sai (75%).
    final texts = [for (var i = 0; i < 20; i++) 'think', for (var i = 0; i < 4; i++) 'light'];
    final errs = [...List.filled(5, 'TH'), ...List.filled(3, 'L')];
    final r = computeWeakSounds(texts, errs);
    expect(r.map((w) => w.phoneme).toList(), ['L', 'TH']);
    expect(r.first.rate, closeTo(0.75, 1e-9));
    expect((r.last.errors, r.last.seen), (5, 20));
  });

  test('âm gặp ít hơn minSeen bị bỏ qua', () {
    final r = computeWeakSounds(['think', 'think'], ['TH', 'TH']);
    expect(r, isEmpty);
  });

  test('không có lỗi thì danh sách rỗng', () {
    expect(computeWeakSounds(['think', 'think', 'think'], []), isEmpty);
  });

  test('chỉ lấy tối đa top âm', () {
    final texts = ['think three', 'think three', 'think three', 'right light', 'right light', 'right light'];
    final errs = [
      for (final p in ['TH', 'R', 'L', 'IY']) ...List.filled(3, p),
    ];
    expect(computeWeakSounds(texts, errs, top: 2), hasLength(2));
  });

  test('cùng tỉ lệ thì sắp xếp ổn định theo số lỗi rồi tên âm', () {
    final texts = List.filled(3, 'right light');
    final r = computeWeakSounds(texts, [...List.filled(3, 'R'), ...List.filled(3, 'L')]);
    expect(r.map((w) => w.phoneme).toList(), ['L', 'R']);
  });
}
