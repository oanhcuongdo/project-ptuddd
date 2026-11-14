import 'package:english_pronunciation_app/data/lessons.dart';
import 'package:english_pronunciation_app/scoring/feedback.dart';
import 'package:english_pronunciation_app/scoring/phonemes.dart';
import 'package:english_pronunciation_app/scoring/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every lesson word is in the dictionary', () {
    for (final l in lessons) {
      for (final item in l.items) {
        for (final w in tokenize(item)) {
          expect(inDictionary(w), isTrue, reason: w);
        }
      }
    }
  });

  test('perfect match scores 100 with no errors', () {
    final r = scorePronunciation('I think three is enough', 'i think three is enough');
    expect(r.score, 100);
    expect(r.errors, isEmpty);
    expect(r.words.every((w) => w.score == 100), isTrue);
  });

  test('empty recognition scores 0', () {
    expect(scorePronunciation('think', '').score, 0);
  });

  test('digits are spelled out', () {
    expect(scorePronunciation('three', '3').score, 100);
  });

  // Simulated accents: what a recognizer returns for typical L1 patterns.
  group('accent simulations', () {
    test('Vietnamese: TH becomes T/S', () {
      final r = scorePronunciation('I think three is enough', 'I sink tree is enough');
      expect(r.score, inInclusiveRange(70, 95));
      final subs = r.errors.map((e) => '${e.expected}>${e.actual}').toList();
      expect(subs, containsAll(['TH>S', 'TH>T']));
      expect(r.words[1].correct.first, isFalse);
      expect(suggestionsFor(r).first.lessonId, 'th');
    });

    test('Vietnamese: dropped final consonant', () {
      final r = scorePronunciation('cats', 'cat');
      expect(r.errors.single.type, ErrorType.deletion);
      expect(r.errors.single.atWordEnd, isTrue);
      expect(suggestionsFor(r).single.lessonId, 'final');
    });

    test('V pronounced as B/W', () {
      final r = scorePronunciation('very', 'berry');
      expect(r.errors.single.expected, 'V');
      expect(suggestionsFor(r).single.lessonId, 'vw');
    });

    test('R/L confusion', () {
      final r = scorePronunciation('right', 'light');
      expect(r.errors.single.describe, '/r/ → /l/');
      expect(suggestionsFor(r).single.lessonId, 'rl');
    });

    test('long/short vowel', () {
      final r = scorePronunciation('sheep', 'ship');
      expect(r.errors.single.expected, 'IY');
      expect(r.score, greaterThan(80));
    });
  });

  test('unrelated words score much lower than near-misses', () {
    final near = scorePronunciation('She sells sea shells', 'see sells sea shells');
    final far = scorePronunciation('She sells sea shells', 'what time is it');
    expect(near.score, greaterThan(far.score + 30));
  });

  test('confidence blends into score', () {
    final r = scorePronunciation('think', 'think', confidence: 0.5);
    expect(r.score, 95);
  });

  test('out-of-dictionary words use letter rules', () {
    expect(phonemesOf('chip'), ['CH', 'IH', 'P']);
    expect(scorePronunciation('chip', 'chip').score, 100);
  });

  test('ipa display', () {
    expect(ipaOfText('think'), '/θɪŋk/');
  });
}
