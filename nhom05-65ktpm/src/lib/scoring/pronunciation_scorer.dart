import 'phonemes.dart';

enum ErrorType { substitution, deletion, insertion }

class PhonemeError {
  final int wordIndex;
  final String word;
  final String? expected; // null for insertion
  final String? actual; // null for deletion
  final ErrorType type;
  final bool atWordEnd;

  const PhonemeError(this.wordIndex, this.word, this.expected, this.actual,
      this.type, this.atWordEnd);

  String get describe => switch (type) {
        ErrorType.substitution => '/${ipa(expected!)}/ → /${ipa(actual!)}/',
        ErrorType.deletion => 'thiếu /${ipa(expected!)}/',
        ErrorType.insertion => 'thừa /${ipa(actual!)}/',
      };
}

class WordResult {
  final String word;
  final List<String> phonemes;
  final List<bool> correct;
  final int score;

  const WordResult(this.word, this.phonemes, this.correct, this.score);
}

class PronunciationResult {
  final String expectedText;
  final String recognizedText;
  final int score;
  final double confidence;
  final List<WordResult> words;
  final List<PhonemeError> errors;

  const PronunciationResult(this.expectedText, this.recognizedText, this.score,
      this.confidence, this.words, this.errors);
}

class _Ph {
  final String p;
  final int word;
  final bool last;
  const _Ph(this.p, this.word, this.last);
}

/// Scores pronunciation by aligning the phonemes of the target text with
/// the phonemes of what the speech recognizer heard (weighted
/// Needleman–Wunsch: similar phonemes cost 0.5, others 1).
PronunciationResult scorePronunciation(String expected, String recognized,
    {double confidence = 0}) {
  final expWords = tokenize(expected);
  final exp = <_Ph>[];
  for (var w = 0; w < expWords.length; w++) {
    final ps = phonemesOf(expWords[w]);
    for (var i = 0; i < ps.length; i++) {
      exp.add(_Ph(ps[i], w, i == ps.length - 1));
    }
  }
  final act = tokenize(recognized).expand(phonemesOf).toList();

  final n = exp.length, m = act.length;
  final d = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0));
  for (var i = 1; i <= n; i++) {
    d[i][0] = i.toDouble();
  }
  for (var j = 1; j <= m; j++) {
    d[0][j] = j.toDouble();
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final sub = d[i - 1][j - 1] + substitutionCost(exp[i - 1].p, act[j - 1]);
      final del = d[i - 1][j] + 1;
      final ins = d[i][j - 1] + 1;
      d[i][j] = [sub, del, ins].reduce((a, b) => a < b ? a : b);
    }
  }

  // Backtrace, attributing each edit to an expected word.
  final correct = List<bool>.filled(n, false);
  final wordCost = List<double>.filled(expWords.length, 0);
  final errors = <PhonemeError>[];
  var i = n, j = m;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final c = substitutionCost(exp[i - 1].p, act[j - 1]);
      if ((d[i][j] - (d[i - 1][j - 1] + c)).abs() < 1e-9) {
        final e = exp[i - 1];
        if (c == 0) {
          correct[i - 1] = true;
        } else {
          wordCost[e.word] += c;
          errors.add(PhonemeError(e.word, expWords[e.word], e.p, act[j - 1],
              ErrorType.substitution, e.last));
        }
        i--;
        j--;
        continue;
      }
    }
    if (i > 0 && (j == 0 || (d[i][j] - (d[i - 1][j] + 1)).abs() < 1e-9)) {
      final e = exp[i - 1];
      wordCost[e.word] += 1;
      errors.add(PhonemeError(
          e.word, expWords[e.word], e.p, null, ErrorType.deletion, e.last));
      i--;
    } else {
      // Extra sound: charge it to the word it follows (or the first word).
      final w = i > 0 ? exp[i - 1].word : 0;
      if (expWords.isNotEmpty) {
        wordCost[w] += 1;
        errors.add(PhonemeError(
            w, expWords[w], null, act[j - 1], ErrorType.insertion, false));
      }
      j--;
    }
  }

  final words = <WordResult>[];
  var k = 0;
  for (var w = 0; w < expWords.length; w++) {
    final ps = phonemesOf(expWords[w]);
    final s = (100 * (1 - wordCost[w] / ps.length)).clamp(0, 100).round();
    words.add(WordResult(expWords[w], ps, correct.sublist(k, k + ps.length), s));
    k += ps.length;
  }

  final total = n == 0 ? 0.0 : (1 - d[n][m] / n).clamp(0.0, 1.0) * 100;
  // Recognizer confidence nudges the score when the engine reports it.
  final blended =
      confidence > 0 ? total * 0.9 + confidence.clamp(0, 1) * 10 : total;
  return PronunciationResult(expected, recognized, m == 0 ? 0 : blended.round(),
      confidence, words, errors.reversed.toList());
}
