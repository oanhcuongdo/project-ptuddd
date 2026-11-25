import 'package:english_pronunciation_app/data/lessons.dart';
import 'package:english_pronunciation_app/scoring/feedback.dart';
import 'package:english_pronunciation_app/scoring/phonemes.dart';
import 'package:english_pronunciation_app/scoring/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mọi âm dễ nhầm đều có mẹo phát âm', () {
    for (final p in confusablePhonemes) {
      expect(suggestionForPhoneme(p), isNotNull, reason: 'thiếu mẹo cho $p');
    }
  });

  test('mẹo trỏ tới bài học có thật và có cặp từ luyện', () {
    for (final p in confusablePhonemes) {
      final s = suggestionForPhoneme(p)!;
      expect(lessons.any((l) => l.id == s.lessonId), isTrue, reason: '$p → ${s.lessonId}');
      expect(s.practiceWords, isNotEmpty, reason: p);
    }
  });

  test('lỗi thay thế phụ âm cuối từ (bat → bad) dùng mẹo phụ âm cuối', () {
    final r = scorePronunciation('bat', 'bad');
    expect(r.errors.single.atWordEnd, isTrue);
    expect(suggestionsFor(r).single.lessonId, 'final');
  });

  test('âm TH ở cuối từ vẫn dùng mẹo TH, không bị nhầm sang phụ âm cuối', () {
    final r = scorePronunciation('mouth', 'mouse');
    expect(suggestionsFor(r).single.lessonId, 'th');
  });

  test('lỗi nguyên âm /æ/ → /e/ có gợi ý bài nguyên âm', () {
    final r = scorePronunciation('bat', 'bet');
    expect(suggestionsFor(r).single.lessonId, 'vowels');
  });
}
