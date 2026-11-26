import 'package:english_pronunciation_app/data/lessons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = lessonById('th'); // 6 mục

  test('chưa luyện gì: 0 mục thành thạo, bắt đầu từ mục đầu', () {
    expect(masteredCount(l, {}), 0);
    expect(firstUnmastered(l, {}), 0);
  });

  test('chỉ tính mục đạt ngưỡng (>= masteryScore)', () {
    final best = {l.items[0]: masteryScore, l.items[1]: masteryScore - 1, 'không thuộc bài': 100};
    expect(masteredCount(l, best), 1);
  });

  test('luyện tiếp từ mục đầu tiên chưa thành thạo, bỏ qua mục đã xong ở đầu', () {
    final best = {l.items[0]: 95, l.items[1]: 90, l.items[2]: 40};
    expect(firstUnmastered(l, best), 2);
  });

  test('mục đã xong nằm sau mục chưa xong không đổi điểm bắt đầu', () {
    expect(firstUnmastered(l, {l.items[3]: 100}), 0);
  });

  test('thành thạo hết thì quay về mục đầu', () {
    final all = {for (final i in l.items) i: 100};
    expect(masteredCount(l, all), l.items.length);
    expect(firstUnmastered(l, all), 0);
  });
}
