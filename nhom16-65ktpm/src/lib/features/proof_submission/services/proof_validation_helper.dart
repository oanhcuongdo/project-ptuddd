import '../mlkit_ocr_service.dart';
import 'proof_image_storage_service.dart';

/// Kết quả kiểm tra sơ bộ minh chứng trước khi gửi lên hàng đợi Admin (Sprint 3 - Giai đoạn 5).
class ProofSubmissionCheck {
  const ProofSubmissionCheck({
    this.blockingError,
    this.warnings = const [],
  });

  /// Lỗi bắt buộc phải sửa mới được phép nộp (ví dụ: bỏ trống tên thành viên).
  final String? blockingError;

  /// Các cảnh báo từ AI OCR hoặc chất lượng tệp ảnh (cho phép người dùng kiểm tra lại hoặc xác nhận vẫn gửi).
  final List<String> warnings;

  bool get canProceedImmediately => blockingError == null && warnings.isEmpty;

  bool get hasBlockingError => blockingError != null;

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Bộ kiểm tra hợp lệ biểu mẫu, chất lượng ảnh và cảnh báo sơ bộ từ AI OCR trước khi gửi duyệt.
class ProofValidationHelper {
  const ProofValidationHelper();

  static const int minMeaningfulTextLength = 6;
  static const int lowConfidenceThreshold = 50;

  /// Đánh giá toàn diện dữ liệu minh chứng trước khi lưu vào cơ sở dữ liệu.
  ProofSubmissionCheck evaluate({
    required String memberName,
    required String selectedChallengeId,
    required String selectedChallengeTitle,
    required StoredProofImage? storedImage,
    required ImageIntegrityResult imageIntegrity,
    required OcrScanResult? ocrResult,
  }) {
    final trimmedName = memberName.trim();
    if (trimmedName.isEmpty) {
      return const ProofSubmissionCheck(
        blockingError:
            'Vui lòng nhập họ và tên thành viên trước khi nộp minh chứng.',
      );
    }

    if (storedImage != null && !imageIntegrity.isValid) {
      return ProofSubmissionCheck(
        blockingError:
            imageIntegrity.message ?? 'Tệp ảnh minh chứng không hợp lệ.',
      );
    }

    final warnings = <String>[];

    if (storedImage == null) {
      warnings.add(
        'Bạn chưa chụp ảnh thực tế từ Camera/Thư viện (hệ thống sẽ gửi kèm dữ liệu mẫu kiểm thử).',
      );
    } else if (imageIntegrity.warningMessage != null) {
      warnings.add(imageIntegrity.warningMessage!);
    }

    if (ocrResult == null || !ocrResult.hasText) {
      warnings.add(
        'AI OCR không đọc được chữ trên ảnh. Ảnh có thể bị mờ, thiếu sáng hoặc chưa chụp rõ nội dung.',
      );
      return ProofSubmissionCheck(warnings: warnings);
    }

    if (ocrResult.rawText.trim().length < minMeaningfulTextLength) {
      warnings.add(
        'Nội dung chữ đọc được quá ít ("${ocrResult.rawText.trim()}"). Hãy đảm bảo ảnh chụp rõ đồng hồ hoặc bài làm.',
      );
    }

    final detail = ocrResult.analysisDetail;

    if (selectedChallengeId == 'ch_01') {
      if (ocrResult.extractedTime == null) {
        warnings.add(
          'Thử thách "$selectedChallengeTitle" yêu cầu có mốc giờ đồng hồ nhưng AI chưa tìm thấy giờ (HH:mm) trên ảnh.',
        );
      } else if (!ocrResult.isEarlyWakeUpValid) {
        warnings.add(
          'Giờ nhận diện trên ảnh (${ocrResult.extractedTime}) nằm ngoài khung giờ dậy sớm quy định (04:00 - 06:00).',
        );
      }
    }

    if (detail != null) {
      if (!detail.isContentMatched && detail.suggestedChallengeId != null) {
        warnings.add(
          'Từ khóa trên ảnh chưa khớp với thử thách "$selectedChallengeTitle" (điểm tin cậy AI: ${detail.confidenceScore}%).',
        );
      } else if (detail.confidenceScore < lowConfidenceThreshold) {
        warnings.add(
          'Điểm xác thực sơ bộ từ AI OCR đang ở mức thấp (${detail.confidenceScore}%). Admin sẽ cần kiểm tra kỹ thủ công.',
        );
      }
    }

    return ProofSubmissionCheck(warnings: warnings);
  }
}
