class SafetyCheckResult {
  final bool isBlocked;
  final String? warningMessage;

  const SafetyCheckResult({
    required this.isBlocked,
    this.warningMessage,
  });
}

class SafetyGuardrails {
  static const String medicationWarning =
      '⚠️ CẢNH BÁO Y TẾ: DCSleep chỉ hỗ trợ tư vấn vệ sinh giấc ngủ và thói quen sinh hoạt khoa học. Ứng dụng tuyệt đối KHÔNG tư vấn, kê đơn hay hướng dẫn sử dụng các loại dược phẩm/thuốc ngủ. Bạn vui lòng liên hệ bác sĩ chuyên khoa để được hướng dẫn y khoa an toàn.';

  static const String redFlagWarning =
      '⚠️ KHUYẾN CÁO KHẨN CẤP: Triệu chứng bạn mô tả có thể là dấu hiệu rối loạn giấc ngủ nghiêm trọng hoặc bệnh lý cần can thiệp y tế. Bạn nên đến ngay cơ sở y tế hoặc bệnh viện chuyên khoa tâm thần/thần kinh để được thăm khám và điều trị kịp thời.';

  // Danh mục từ khóa dược lý / thuốc ngủ (dạng không dấu, chữ thường)
  static const List<String> _medicationKeywords = [
    'thuoc ngu',
    'thuoc an than',
    'seduxen',
    'stilnox',
    'zolpidem',
    'diazepam',
    'rotunda',
    'uong thuoc gi',
    'lieu luong thuoc',
    'thuoc ho tro ngu',
    'mua thuoc',
  ];

  // Danh mục triệu chứng báo động đỏ lâm sàng (dạng không dấu, chữ thường)
  static const List<String> _redFlagKeywords = [
    'ngung tho khi ngu',
    'co giat',
    'ao giac',
    'suy nhuoc cap',
    'mat ngu kinh nien',
  ];

  /// Loại bỏ toàn bộ dấu tiếng Việt và chuyển sang chữ thường chuẩn hóa
  static String removeDiacritics(String text) {
    var result = text.toLowerCase();
    const vietnameseMap = {
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'd': 'đ',
      'e': 'éèẻẽẹêếềểễệ',
      'i': 'íìỉĩị',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'u': 'úùủũụưứừửữự',
      'y': 'ýỳỷỹỵ',
    };

    for (final entry in vietnameseMap.entries) {
      for (final char in entry.value.split('')) {
        result = result.replaceAll(char, entry.key);
      }
    }
    return result;
  }

  /// Đánh giá tiền xử lý prompt của người dùng
  static SafetyCheckResult evaluate(String prompt) {
    if (prompt.trim().isEmpty) {
      return const SafetyCheckResult(isBlocked: false);
    }

    final normalized = removeDiacritics(prompt);

    // 1. Kiểm tra dược lý / thuốc ngủ
    for (final kw in _medicationKeywords) {
      if (normalized.contains(kw)) {
        return const SafetyCheckResult(
          isBlocked: true,
          warningMessage: medicationWarning,
        );
      }
    }

    // 2. Kiểm tra triệu chứng Red Flags
    for (final rf in _redFlagKeywords) {
      if (normalized.contains(rf)) {
        return const SafetyCheckResult(
          isBlocked: true,
          warningMessage: redFlagWarning,
        );
      }
    }

    return const SafetyCheckResult(isBlocked: false);
  }
}
