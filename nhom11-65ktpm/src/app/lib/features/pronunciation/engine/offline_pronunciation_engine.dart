import 'dart:math';
import '../../../../core/contracts/models/pronunciation.dart';
import '../../../../core/contracts/pronunciation_scorer.dart';

/// Thuat toan can chinh am tiet va ma tran phat loi nguoi Viet.
/// Chu so huu: Khanh (#13)
class OfflinePronunciationEngine implements PronunciationScorer {
  static const Map<String, List<String>> _confusableInitials = {
    'zh': ['z', 'j'],
    'z': ['zh'],
    'ch': ['c', 'q'],
    'c': ['ch'],
    'sh': ['s', 'x'],
    's': ['sh'],
    'j': ['q', 'zh', 'z', 'x'],
    'q': ['ch', 'j', 'c'],
    'x': ['s', 'sh', 'j'],
    'l': ['n'],
    'n': ['l'],
    'h': ['k'],
    'r': ['l', 'z', 'd'],
  };

  static const Map<String, List<String>> _confusableFinals = {
    'u': ['ü', 'v', 'ou'],
    'ü': ['u', 'v'],
    'an': ['ang'],
    'ang': ['an'],
    'en': ['eng'],
    'eng': ['en'],
    'in': ['ing'],
    'ing': ['in'],
    'ian': ['iang', 'en'],
    'iang': ['ian'],
    'uan': ['uang'],
    'uang': ['uan'],
  };

  @override
  Future<PronunciationResult> assess({
    required String referenceHanzi,
    required String referencePinyin,
    Recording? recording,
    String? recognizedPinyin,
    String? recognizedText,
  }) async {
    final chars = referenceHanzi.runes
        .map(String.fromCharCode)
        .where((c) => RegExp(r'[一-鿿]').hasMatch(c))
        .toList();
    final expSyls = referencePinyin.trim().split(RegExp(r'\s+'));

    final hasText = (recognizedText != null && recognizedText.trim().isNotEmpty) ||
        (recognizedPinyin != null && recognizedPinyin.trim().isNotEmpty);

    // Chi coi la bam nham neu ghi am duoi 300ms VA khong he nhan dien duoc chu nao
    if (recording != null && recording.duration.inMilliseconds < 300 && !hasText) {
      return PronunciationResult(
        overall: 0.0,
        accuracy: 0.0,
        tone: 0.0,
        fluency: 0.0,
        completeness: 0.0,
        source: ScoringSource.offline,
        recognizedText: '',
        syllables: [
          for (var i = 0; i < chars.length; i++)
            SyllableScore(
              hanzi: chars[i],
              expected: splitPinyin(i < expSyls.length ? expSyls[i] : ''),
              actual: null,
              score: 0.0,
              status: SyllableStatus.error,
              errors: const [PronunciationError.missing],
            ),
        ],
      );
    }

    // Neu ghi am that ma hoan toan im lang, khong bat duoc chu nao
    if (recording != null && !hasText) {
      return PronunciationResult(
        overall: 0.0,
        accuracy: 0.0,
        tone: 0.0,
        fluency: 0.0,
        completeness: 0.0,
        source: ScoringSource.offline,
        recognizedText: recognizedText ?? '',
        syllables: [
          for (var i = 0; i < chars.length; i++)
            SyllableScore(
              hanzi: chars[i],
              expected: splitPinyin(i < expSyls.length ? expSyls[i] : ''),
              actual: null,
              score: 0.0,
              status: SyllableStatus.error,
              errors: const [PronunciationError.missing],
            ),
        ],
      );
    }

    var actSyls = (recognizedPinyin != null && recognizedPinyin.trim().isNotEmpty)
        ? recognizedPinyin.trim().split(RegExp(r'\s+'))
        : <String>[];

    // Fallback phong thu: Neu recognizedPinyin rong nhung recognizedText co chu Han
    if (actSyls.isEmpty && recognizedText != null && recognizedText.trim().isNotEmpty) {
      final actChars = recognizedText.runes
          .map(String.fromCharCode)
          .where((c) => RegExp(r'[一-鿿]').hasMatch(c))
          .toList();
      if (actChars.isNotEmpty) {
        actSyls = [for (var i = 0; i < actChars.length; i++) i < expSyls.length ? expSyls[i] : ''];
      }
    }

    final expPartsList = <SyllableParts>[];
    for (var i = 0; i < chars.length; i++) {
      final expPinyinStr = i < expSyls.length ? expSyls[i] : '';
      expPartsList.add(splitPinyin(expPinyinStr));
    }

    final bool isMockDefault = (recording == null && actSyls.isEmpty);
    final actPartsList = isMockDefault
        ? expPartsList
        : actSyls.map((s) => splitPinyin(s)).toList();

    final alignedActList = isMockDefault
        ? expPartsList.map((e) => e as SyllableParts?).toList()
        : _alignSyllables(expPartsList, actPartsList);

    final syllablesScore = <SyllableScore>[];
    double totalScore = 0.0;
    double totalAccuracy = 0.0;
    double totalTone = 0.0;
    int recognizedCount = 0;

    for (var i = 0; i < chars.length; i++) {
      final hanzi = chars[i];
      final expected = expPartsList[i];

      if (expected.initial.isEmpty && expected.finalPart.isEmpty) {
        continue;
      }

      final SyllableParts? actual = alignedActList[i];
      if (actual == null) {
        syllablesScore.add(SyllableScore(
          hanzi: hanzi,
          expected: expected,
          actual: null,
          score: 0.0,
          status: SyllableStatus.error,
          errors: const [PronunciationError.missing],
        ));
        continue;
      }

      recognizedCount++;

      final errors = <PronunciationError>[];
      double initialPen = 0.0;
      double finalPen = 0.0;
      double tonePen = 0.0;

      if (expected.initial != actual.initial) {
        errors.add(PronunciationError.initial);
        if (_confusableInitials[expected.initial]?.contains(actual.initial) == true) {
          initialPen = 15.0;
        } else {
          initialPen = 40.0;
        }
      }

      if (expected.finalPart != actual.finalPart) {
        errors.add(PronunciationError.finalPart);
        if (_confusableFinals[expected.finalPart]?.contains(actual.finalPart) == true) {
          finalPen = 15.0;
        } else {
          finalPen = 40.0;
        }
      }

      if (expected.tone != actual.tone) {
        errors.add(PronunciationError.tone);
        tonePen = 45.0;
      }

      double score;
      double acc;
      double toneSc;
      SyllableStatus status;

      if (initialPen >= 40.0 && finalPen >= 40.0) {
        score = 0.0;
        acc = 0.0;
        toneSc = 0.0;
        status = SyllableStatus.error;
      } else {
        final wordPenalty = initialPen * 0.40 + finalPen * 0.40 + tonePen * 0.50;
        score = max(0.0, 100.0 - wordPenalty);
        acc = max(0.0, 100.0 - (initialPen + finalPen));
        toneSc = max(0.0, 100.0 - tonePen * 2.0);

        if (errors.contains(PronunciationError.initial) && errors.contains(PronunciationError.tone)) {
          status = SyllableStatus.error;
        } else if (errors.contains(PronunciationError.tone)) {
          status = tonePen >= 40.0 ? SyllableStatus.error : SyllableStatus.warn;
        } else if (score < 60) {
          status = SyllableStatus.error;
        } else if (score < 80) {
          status = SyllableStatus.warn;
        } else {
          status = SyllableStatus.ok;
        }
      }

      syllablesScore.add(SyllableScore(
        hanzi: hanzi,
        expected: expected,
        actual: actual,
        score: score.roundToDouble(),
        status: status,
        errors: errors,
      ));

      totalScore += score;
      totalAccuracy += acc;
      totalTone += toneSc;
    }

    final n = chars.isEmpty ? 1 : chars.length;
    final avgScore = (totalScore / n).roundToDouble();
    final avgAccuracy = (totalAccuracy / n).roundToDouble();
    final avgTone = (totalTone / n).roundToDouble();

    double fluency = 92.0;
    if (recording != null && recording.duration.inMilliseconds > 0) {
      final expectedDurationMs = chars.length * 600;
      final actualMs = recording.duration.inMilliseconds;
      final ratio = actualMs / expectedDurationMs;
      if (ratio > 2.0 || ratio < 0.4) {
        fluency = max(60.0, 92.0 - (ratio - 1.0).abs() * 20.0).roundToDouble();
      }
    }

    final completeness = chars.isNotEmpty
        ? ((recognizedCount / chars.length) * 100.0).clamp(0.0, 100.0).roundToDouble()
        : 100.0;

    return PronunciationResult(
      overall: avgScore,
      accuracy: avgAccuracy,
      tone: avgTone,
      fluency: fluency,
      completeness: completeness,
      source: ScoringSource.offline,
      recognizedText: recognizedText ?? (actSyls.isNotEmpty ? actSyls.join(' ') : referenceHanzi),
      syllables: syllablesScore,
    );
  }

  /// Căn chỉnh âm tiết mong đợi (expected) và âm tiết đọc được (actual).
  /// Giải quyết trường hợp đọc thiếu âm tiết ở đầu (ví dụ đọc "hǎo" thay vì "nǐ hǎo"),
  /// không làm lệch toàn bộ các âm tiết phía sau.
  List<SyllableParts?> _alignSyllables(List<SyllableParts> expList, List<SyllableParts> actList) {
    if (actList.isEmpty) {
      return List<SyllableParts?>.filled(expList.length, null);
    }

    final n = expList.length;
    final m = actList.length;

    int matchScore(SyllableParts e, SyllableParts a) {
      if (e.initial == a.initial && e.finalPart == a.finalPart && e.tone == a.tone) {
        return 10;
      }
      if (e.initial == a.initial && e.finalPart == a.finalPart) {
        return 8;
      }
      if (e.finalPart == a.finalPart) {
        return 4;
      }
      if (e.initial == a.initial) {
        return 3;
      }
      return -2;
    }

    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));

    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final score = matchScore(expList[i - 1], actList[j - 1]);
        dp[i][j] = max(
          dp[i - 1][j - 1] + score,
          max(dp[i - 1][j], dp[i][j - 1]),
        );
      }
    }

    final aligned = List<SyllableParts?>.filled(n, null);
    var i = n;
    var j = m;

    while (i > 0 && j > 0) {
      final score = matchScore(expList[i - 1], actList[j - 1]);
      if (dp[i][j] == dp[i - 1][j - 1] + score && score > 0) {
        aligned[i - 1] = actList[j - 1];
        i--;
        j--;
      } else if (dp[i][j] == dp[i - 1][j]) {
        aligned[i - 1] = null;
        i--;
      } else {
        j--;
      }
    }

    return aligned;
  }
}
