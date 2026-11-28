import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/features/proof_submission/data/mock_ocr_samples.dart';
import 'package:gooddeeds_fund/features/proof_submission/models/ocr_analysis_detail.dart';

void main() {
  group('OcrAnalysisDetail & MockOcrSample Unit Tests (Sprint 3 - Stage 1)', () {
    test('Phân loại đúng mức độ tin cậy OcrConfidenceLevel theo điểm số', () {
      const highDetail = OcrAnalysisDetail(
        rawText: '05:30 AM - Học bài Flutter',
        extractedTime: '05:30',
        confidenceScore: 90,
        isTimeValid: true,
        isContentMatched: true,
      );
      expect(highDetail.hasText, isTrue);
      expect(highDetail.confidenceLevel, OcrConfidenceLevel.high);
      expect(highDetail.confidenceBadgeLabel, 'Độ tin cậy cao (90%)');

      const mediumDetail = OcrAnalysisDetail(
        rawText: '06:15 - Bài tập toán',
        confidenceScore: 65,
      );
      expect(mediumDetail.confidenceLevel, OcrConfidenceLevel.medium);

      const lowDetail = OcrAnalysisDetail(
        rawText: 'Ảnh mờ ít chữ',
        confidenceScore: 25,
      );
      expect(lowDetail.confidenceLevel, OcrConfidenceLevel.low);

      const emptyDetail = OcrAnalysisDetail(
        rawText: '   ',
        confidenceScore: 0,
      );
      expect(emptyDetail.hasText, isFalse);
      expect(emptyDetail.confidenceLevel, OcrConfidenceLevel.unverified);
    });

    test('Hàm copyWith của OcrAnalysisDetail giữ nguyên và cập nhật đúng trường', () {
      const initial = OcrAnalysisDetail(
        rawText: '05:40 - Ôn tập',
        extractedTime: '05:40',
        confidenceScore: 70,
      );
      final updated = initial.copyWith(
        confidenceScore: 95,
        suggestedChallengeId: 'ch_01',
        isTimeValid: true,
      );

      expect(updated.rawText, '05:40 - Ôn tập');
      expect(updated.extractedTime, '05:40');
      expect(updated.confidenceScore, 95);
      expect(updated.suggestedChallengeId, 'ch_01');
      expect(updated.isTimeValid, isTrue);
    });

    test('Bộ dữ liệu mẫu mockOcrSamples bao phủ đầy đủ 4 loại thử thách', () {
      expect(mockOcrSamples.length, greaterThanOrEqualTo(6));
      final challengeIds = mockOcrSamples.map((s) => s.challengeId).toSet();
      expect(challengeIds, containsAll(['ch_01', 'ch_02', 'ch_03', 'ch_04']));
    });
  });
}
