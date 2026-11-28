/// Dịch vụ Trợ lý Hỏi Đáp Thông Minh (AI Q&A Assistant Service)
/// Phụ trách: Nguyễn Văn Huỳnh (Nhóm trưởng)
class QaAssistantService {
  QaAssistantService._internal();
  static final QaAssistantService instance = QaAssistantService._internal();

  /// Cơ sở tri thức trả lời tự động cho GoodDeeds Fund
  final List<Map<String, dynamic>> _knowledgeBase = [
    {
      'keywords': ['quỹ', 'số dư', 'tiền', 'bao nhiêu'],
      'reply':
          '💡 Số dư Quỹ GoodDeeds Fund hiện tại được bảo vệ và đồng bộ trực tiếp từ SQLite Database. Bạn có thể xem con số chính xác tại Trang chủ (Dashboard) hoặc tab Sổ Quỹ!',
    },
    {
      'keywords': ['dậy sớm', '6h', 'giờ', 'sáng'],
      'reply':
          '⏰ Thể lệ Thử thách Dậy sớm:\n- Bạn cần chụp ảnh bàn học, đồng hồ hoặc báo thức trước 6:00 sáng.\n- AI OCR sẽ tự động quét định dạng giờ (HH:mm) trên ảnh để xác thực sơ bộ.\n- Mức tài trợ: +20.000 đ vào quỹ khi Admin duyệt!',
    },
    {
      'keywords': ['ocr', 'ảnh', 'mờ', 'chụp', 'minh chứng'],
      'reply':
          '📸 Mẹo nộp minh chứng thành công:\n- Đặt camera vuông góc với đồng hồ / trang sách.\n- Đảm bảo đủ ánh sáng, không bị lóa đèn.\n- Giữ nét chữ rõ ràng để Google ML Kit nhận diện chính xác 100%!',
    },
    {
      'keywords': ['giải ngân', 'chi', 'rút', 'từ thiện', 'trường'],
      'reply':
          '🤝 Quy định Giải ngân Từ thiện:\n- Mọi khoản chi giải ngân bắt buộc phải có biên nhận, ảnh sao kê hoặc hóa đơn chuyển khoản thực tế.\n- Dữ liệu chi được công khai minh bạch 100% trong Sổ Quỹ và biểu đồ tài chính!',
    },
    {
      'keywords': ['admin', 'duyệt', 'từ chối', 'kiểm duyệt'],
      'reply':
          '🛡️ Quy trình Phê duyệt:\n- Minh chứng sau khi nộp sẽ ở trạng thái "Chờ duyệt".\n- Admin đối chiếu kết quả OCR và ảnh thực tế.\n- Khi Admin bấm "Duyệt", số tiền tài trợ sẽ tự động được cộng vào Quỹ chung!',
    },
  ];

  /// Gợi ý câu hỏi nhanh (Quick Prompts)
  final List<String> quickPrompts = [
    'Thể lệ dậy sớm trước 6:00 sáng?',
    'Số dư quỹ tra cứu ở đâu?',
    'Mẹo chụp ảnh để AI OCR đọc rõ?',
    'Quy chế giải ngân từ thiện?',
  ];

  /// Xử lý câu hỏi của người dùng và trả lời
  String answerQuestion(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) {
      return 'Bạn có câu hỏi nào về quy chế hay cách nộp minh chứng không? Mình luôn sẵn sàng hỗ trợ!';
    }

    for (final item in _knowledgeBase) {
      final keywords = item['keywords'] as List<String>;
      for (final kw in keywords) {
        if (lower.contains(kw)) {
          return item['reply'] as String;
        }
      }
    }

    return 'Cảm ơn câu hỏi của bạn! Trợ lý AI đang tiếp tục học hỏi thêm. Bạn có thể xem chi tiết trong mục Thử thách hoặc liên hệ Nhóm trưởng Huỳnh (2351170599) nhé!';
  }
}
