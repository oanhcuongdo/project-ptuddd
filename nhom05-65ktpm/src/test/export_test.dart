import 'package:english_pronunciation_app/data/export.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> row(String expected, String heard,
        {int score = 90, double confidence = 0.8, String at = '2026-11-21T20:05:00.000'}) =>
    {
      'expected_text': expected,
      'recognized_text': heard,
      'score': score,
      'confidence': confidence,
      'created_at': at,
    };

void main() {
  test('chỉ có dòng tiêu đề khi chưa có lượt nói', () {
    expect(attemptsToCsv([]).trim().split('\n'), hasLength(1));
  });

  test('mỗi lượt nói một dòng, có lỗi âm vị cho câu đọc sai', () {
    final lines = attemptsToCsv([row('think', 'sink', score: 83)]).trim().split('\n');
    expect(lines, hasLength(2));
    expect(lines[1], startsWith('2026-11-21T20:05:00.000,think,sink,83,0.80,'));
    expect(lines[1], contains('think: /θ/ → /s/'));
  });

  test('đọc đúng thì cột lỗi để trống', () {
    final line = attemptsToCsv([row('think', 'think')]).trim().split('\n')[1];
    expect(line.endsWith(','), isTrue);
  });

  test('dấu phẩy, dấu nháy và xuống dòng được bọc nháy kép', () {
    final csv = attemptsToCsv([row('Nice to meet you', 'nice, to "meet" you')]);
    expect(csv, contains('"nice, to ""meet"" you"'));
  });

  test('nhiều lỗi trong một lượt ngăn cách bằng dấu chấm phẩy, không cần bọc nháy', () {
    final line = attemptsToCsv([row('I think three is enough', 'I sink tree is enough')])
        .trim()
        .split('\n')[1];
    expect(line, endsWith(',think: /θ/ → /s/; three: /θ/ → /t/'));
    expect(line.split(',').length, 6); // đúng 6 cột, dấu chấm phẩy không tách cột
  });
}
