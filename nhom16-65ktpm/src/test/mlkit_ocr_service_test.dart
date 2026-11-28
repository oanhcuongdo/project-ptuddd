import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/features/proof_submission/data/mock_ocr_samples.dart';
import 'package:gooddeeds_fund/features/proof_submission/mlkit_ocr_service.dart';
import 'package:gooddeeds_fund/features/proof_submission/services/proof_image_storage_service.dart';
import 'package:gooddeeds_fund/features/proof_submission/services/proof_validation_helper.dart';

void main() {
  group('MlKitOcrService & ProofValidationHelper Integration Tests (Sprint 3 - Stage 6)', () {
    late MlKitOcrService ocrService;
    const validationHelper = ProofValidationHelper();

    setUp(() {
      ocrService = MlKitOcrService();
    });

    tearDown(() async {
      await ocrService.dispose();
    });

    test('Phân tích mẫu Dậy sớm hợp lệ trả về điểm tin cậy cao và gợi ý Duyệt cho Admin', () {
      final earlySample = mockOcrSamples.firstWhere(
        (s) => s.id == 'sample_early_valid',
      );
      final result = ocrService.analyzeText(
        earlySample.sampleText,
        targetChallengeId: 'ch_01',
      );

      expect(result.hasText, isTrue);
      expect(result.extractedTime, '05:42');
      expect(result.isEarlyWakeUpValid, isTrue);
      expect(result.analysisDetail, isNotNull);
      expect(result.analysisDetail!.confidenceScore, greaterThanOrEqualTo(70));

      final adminHint = ocrService.buildAdminReviewHint(result);
      expect(adminHint, contains('Giờ: 05:42'));
      expect(adminHint, startsWith('[AI '));
    });

    test('Sinh gợi ý kiểm tra thủ công cho Admin khi ảnh rỗng hoặc mờ không chữ', () {
      final emptyResult = ocrService.analyzeText('   ', targetChallengeId: 'ch_01');
      expect(emptyResult.hasText, isFalse);

      final adminHint = ocrService.buildAdminReviewHint(emptyResult);
      expect(adminHint, contains('Chưa đọc được chữ'));
    });

    test('ProofValidationHelper chặn gửi khi bỏ trống tên thành viên và cảnh báo khi trễ giờ', () {
      final lateSample = mockOcrSamples.firstWhere(
        (s) => s.id == 'sample_early_late',
      );
      final lateResult = ocrService.analyzeText(
        lateSample.sampleText,
        targetChallengeId: 'ch_01',
      );

      // 1. Bỏ trống tên thành viên -> chặn gửi
      final blocked = validationHelper.evaluate(
        memberName: '   ',
        selectedChallengeId: 'ch_01',
        selectedChallengeTitle: 'Dậy sớm trước 6:00 sáng',
        storedImage: null,
        imageIntegrity: const ImageIntegrityResult(isValid: true),
        ocrResult: lateResult,
      );
      expect(blocked.hasBlockingError, isTrue);

      // 2. Có tên nhưng trễ giờ (07:25) -> phát sinh cảnh báo
      final warned = validationHelper.evaluate(
        memberName: 'Nguyễn Trung Kiên',
        selectedChallengeId: 'ch_01',
        selectedChallengeTitle: 'Dậy sớm trước 6:00 sáng',
        storedImage: StoredProofImage(
          savedPath: '/tmp/proof_01.jpg',
          fileName: 'proof_01.jpg',
          fileSizeBytes: 120 * 1024,
          savedAt: DateTime(2026, 11, 27, 7, 25),
        ),
        imageIntegrity: const ImageIntegrityResult(isValid: true),
        ocrResult: lateResult,
      );
      expect(warned.hasBlockingError, isFalse);
      expect(warned.hasWarnings, isTrue);
      expect(
        warned.warnings.any((w) => w.contains('07:25')),
        isTrue,
      );
    });
  });
}
