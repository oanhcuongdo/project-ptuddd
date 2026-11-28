/// Mức độ đánh giá độ tin cậy sơ bộ từ thuật toán AI OCR (Sprint 3).
enum OcrConfidenceLevel {
  high,
  medium,
  low,
  unverified,
}

/// Model lưu trữ chi tiết kết quả phân tích AI OCR từ ảnh minh chứng check-in (Sprint 3).
/// Hỗ trợ nhận diện giờ đồng hồ, ngày tháng, nội dung bài làm và chấm điểm khớp thử thách.
class OcrAnalysisDetail {
  const OcrAnalysisDetail({
    required this.rawText,
    this.extractedTime,
    this.extractedDate,
    this.detectedPeriod,
    this.suggestedChallengeId,
    this.suggestedCategory,
    this.matchedKeywords = const [],
    this.homeworkMetrics = const {},
    this.confidenceScore = 0,
    this.isTimeValid = false,
    this.isContentMatched = false,
    this.summaryMessage = '',
  });

  /// Toàn bộ văn bản thô bóc tách được từ ảnh minh chứng.
  final String rawText;

  /// Giờ đồng hồ chuẩn hóa (định dạng 24h: HH:mm, ví dụ '05:42').
  final String? extractedTime;

  /// Ngày tháng nhận diện được trên ảnh (định dạng dd/MM/yyyy, nếu có).
  final String? extractedDate;

  /// Buổi trong ngày suy luận từ giờ đồng hồ ('Sáng sớm', 'Buổi sáng', 'Buổi chiều', 'Buổi tối').
  final String? detectedPeriod;

  /// Mã thử thách gợi ý dựa trên nội dung chữ đọc được trên ảnh (vd: 'ch_01', 'ch_02'...).
  final String? suggestedChallengeId;

  /// Danh mục thử thách gợi ý ('Kỷ luật', 'Gia sư', 'Học tập', 'Sức khỏe').
  final String? suggestedCategory;

  /// Danh sách các từ khóa bài làm / hoạt động phát hiện được trên ảnh.
  final List<String> matchedKeywords;

  /// Các chỉ số định lượng đọc được từ bài làm (vd: {'so_bai_tap': '5', 'quang_duong_km': '3.2'}).
  final Map<String, String> homeworkMetrics;

  /// Điểm tin cậy sơ bộ của minh chứng do AI chấm (thang điểm 0 - 100).
  final int confidenceScore;

  /// Đánh dấu mốc thời gian trên ảnh có hợp lệ với quy định thử thách hay không.
  final bool isTimeValid;

  /// Đánh dấu nội dung chữ trên bài làm có khớp với loại thử thách đã chọn hay không.
  final bool isContentMatched;

  /// Thông điệp kết luận chi tiết của AI để gợi ý cho người nộp và Admin duyệt.
  final String summaryMessage;

  bool get hasText => rawText.trim().isNotEmpty;

  /// Phân loại mức độ tin cậy dựa trên điểm số [confidenceScore].
  OcrConfidenceLevel get confidenceLevel {
    if (!hasText) return OcrConfidenceLevel.unverified;
    if (confidenceScore >= 80) return OcrConfidenceLevel.high;
    if (confidenceScore >= 50) return OcrConfidenceLevel.medium;
    return OcrConfidenceLevel.low;
  }

  /// Nhãn tiếng Việt mô tả mức độ tin cậy của kết quả OCR.
  String get confidenceBadgeLabel {
    switch (confidenceLevel) {
      case OcrConfidenceLevel.high:
        return 'Độ tin cậy cao ($confidenceScore%)';
      case OcrConfidenceLevel.medium:
        return 'Độ tin cậy trung bình ($confidenceScore%)';
      case OcrConfidenceLevel.low:
        return 'Độ tin cậy thấp ($confidenceScore%)';
      case OcrConfidenceLevel.unverified:
        return 'Chưa nhận diện được chữ';
    }
  }

  OcrAnalysisDetail copyWith({
    String? rawText,
    String? extractedTime,
    String? extractedDate,
    String? detectedPeriod,
    String? suggestedChallengeId,
    String? suggestedCategory,
    List<String>? matchedKeywords,
    Map<String, String>? homeworkMetrics,
    int? confidenceScore,
    bool? isTimeValid,
    bool? isContentMatched,
    String? summaryMessage,
  }) {
    return OcrAnalysisDetail(
      rawText: rawText ?? this.rawText,
      extractedTime: extractedTime ?? this.extractedTime,
      extractedDate: extractedDate ?? this.extractedDate,
      detectedPeriod: detectedPeriod ?? this.detectedPeriod,
      suggestedChallengeId: suggestedChallengeId ?? this.suggestedChallengeId,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      matchedKeywords: matchedKeywords ?? this.matchedKeywords,
      homeworkMetrics: homeworkMetrics ?? this.homeworkMetrics,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isTimeValid: isTimeValid ?? this.isTimeValid,
      isContentMatched: isContentMatched ?? this.isContentMatched,
      summaryMessage: summaryMessage ?? this.summaryMessage,
    );
  }
}
