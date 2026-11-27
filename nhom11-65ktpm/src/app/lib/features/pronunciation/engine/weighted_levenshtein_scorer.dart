import 'pinyin_segmenter.dart';
import 'vietnamese_error_matrix.dart';
import 'dart:math' as math;

class PhonemeEvaluation {
  final String hanzi;
  final String expectedPinyin;
  final String actualPinyin;
  final String expectedInitial;
  final String actualInitial;
  final String expectedFinal;
  final String actualFinal;
  final int expectedTone;
  final int actualTone;
  final double score;
  final bool isInitialError;
  final bool isFinalError;
  final bool isToneError;

  PhonemeEvaluation({
    required this.hanzi,
    required this.expectedPinyin,
    required this.actualPinyin,
    required this.expectedInitial,
    required this.actualInitial,
    required this.expectedFinal,
    required this.actualFinal,
    required this.expectedTone,
    required this.actualTone,
    required this.score,
    required this.isInitialError,
    required this.isFinalError,
    required this.isToneError,
  });

  Map<String, dynamic> toJson() => {
    'hanzi': hanzi,
    'expectedPinyin': expectedPinyin,
    'actualPinyin': actualPinyin,
    'expectedInitial': expectedInitial,
    'actualInitial': actualInitial,
    'expectedFinal': expectedFinal,
    'actualFinal': actualFinal,
    'expectedTone': expectedTone,
    'actualTone': actualTone,
    'score': score,
    'isInitialError': isInitialError,
    'isFinalError': isFinalError,
    'isToneError': isToneError,
  };
}

class PronunciationAssessmentResult {
  final double overallScore;
  final double accuracyScore;
  final double toneScore;
  final double fluencyScore;
  final double completenessScore;
  final List<PhonemeEvaluation> words;
  final String engine; // 'offline' hoac 'azure'

  PronunciationAssessmentResult({
    required this.overallScore,
    required this.accuracyScore,
    required this.toneScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.words,
    required this.engine,
  });

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'accuracyScore': accuracyScore,
    'toneScore': toneScore,
    'fluencyScore': fluencyScore,
    'completenessScore': completenessScore,
    'engine': engine,
    'words': words.map((w) => w.toJson()).toList(),
  };
}

class WeightedLevenshteinScorer {
  static PronunciationAssessmentResult score({
    required List<String> expectedHanzi,
    required List<String> expectedPinyin,
    required List<String> actualPinyin,
    double durationSeconds = 2.0,
  }) {
    final evaluations = <PhonemeEvaluation>[];
    double totalToneScore = 0.0;
    double totalAccuracy = 0.0;

    final n = expectedPinyin.length;
    final m = actualPinyin.length;

    for (int i = 0; i < n; i++) {
      final expP = expectedPinyin[i];
      final expHz = i < expectedHanzi.length ? expectedHanzi[i] : '';
      final expSeg = PinyinSegmenter.segment(expP);

      if (i < m) {
        final actP = actualPinyin[i];
        final actSeg = PinyinSegmenter.segment(actP);

        final initialPenalty = VietnameseErrorMatrix.calculateInitialPenalty(expSeg.initial, actSeg.initial);
        final finalPenalty = VietnameseErrorMatrix.calculateFinalPenalty(expSeg.finalPart, actSeg.finalPart);
        final tonePenalty = VietnameseErrorMatrix.calculateTonePenalty(expSeg.tone, actSeg.tone);

        final wordPenalty = initialPenalty * 0.35 + finalPenalty * 0.35 + tonePenalty * 0.30;
        final wordScore = math.max(0.0, 100.0 - wordPenalty);
        final singleToneScore = math.max(0.0, 100.0 - tonePenalty * 2.5);
        final singleAccuracy = math.max(0.0, 100.0 - (initialPenalty + finalPenalty));

        evaluations.add(PhonemeEvaluation(
          hanzi: expHz,
          expectedPinyin: expP,
          actualPinyin: actP,
          expectedInitial: expSeg.initial,
          actualInitial: actSeg.initial,
          expectedFinal: expSeg.finalPart,
          actualFinal: actSeg.finalPart,
          expectedTone: expSeg.tone,
          actualTone: actSeg.tone,
          score: double.parse(wordScore.toStringAsFixed(1)),
          isInitialError: initialPenalty > 0,
          isFinalError: finalPenalty > 0,
          isToneError: tonePenalty > 0,
        ));

        totalToneScore += singleToneScore;
        totalAccuracy += singleAccuracy;
      } else {
        // Nguoi hoc bo sot tu nay
        evaluations.add(PhonemeEvaluation(
          hanzi: expHz,
          expectedPinyin: expP,
          actualPinyin: '',
          expectedInitial: expSeg.initial,
          actualInitial: '',
          expectedFinal: expSeg.finalPart,
          actualFinal: '',
          expectedTone: expSeg.tone,
          actualTone: 5,
          score: 0.0,
          isInitialError: true,
          isFinalError: true,
          isToneError: true,
        ));
      }
    }

    final completeness = n > 0 ? (math.min(m, n) / n) * 100.0 : 100.0;
    final avgAccuracy = n > 0 ? totalAccuracy / n : 0.0;
    final avgTone = n > 0 ? totalToneScore / n : 0.0;
    final fluency = math.min(100.0, math.max(40.0, 100.0 - (durationSeconds > 5.0 ? (durationSeconds - 5.0) * 8.0 : 0.0)));

    final overall = avgAccuracy * 0.40 + avgTone * 0.35 + fluency * 0.15 + completeness * 0.10;

    return PronunciationAssessmentResult(
      overallScore: double.parse(overall.toStringAsFixed(1)),
      accuracyScore: double.parse(avgAccuracy.toStringAsFixed(1)),
      toneScore: double.parse(avgTone.toStringAsFixed(1)),
      fluencyScore: double.parse(fluency.toStringAsFixed(1)),
      completenessScore: double.parse(completeness.toStringAsFixed(1)),
      words: evaluations,
      engine: 'offline',
    );
  }
}
