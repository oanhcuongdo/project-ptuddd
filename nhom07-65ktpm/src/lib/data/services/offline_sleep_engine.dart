import 'package:dcsleep/data/services/safety_guardrails.dart';

class _WeightedKeyword {
  final String phrase;
  final int weight;

  const _WeightedKeyword(this.phrase, this.weight);
}

class _SleepTopic {
  final String id;
  final String title;
  final List<_WeightedKeyword> keywords;
  final String Function(String? sleepContext) responseBuilder;

  const _SleepTopic({
    required this.id,
    required this.title,
    required this.keywords,
    required this.responseBuilder,
  });
}

/// Bộ tri thức chuyên gia ngoại tuyến nâng cao (OfflineSleepEngine)
/// Hỗ trợ 8 chủ đề giấc ngủ chuyên sâu, chấm điểm từ khóa có trọng số (Weighted Scoring),
/// chuẩn hóa làm sạch dấu câu/tiếng Việt không dấu và tự động kèm miễn trừ y tế chuẩn.
class OfflineSleepEngine {
  /// Số lượng chủ đề chuyên gia được hỗ trợ trong bộ tri thức
  static const int supportedTopicCount = 8;

  static const String _disclaimer =
      '*Lưu ý: Lời khuyên mang tính chất hỗ trợ xây dựng thói quen khoa học, không thay thế chỉ định y tế.*';

  static final List<_SleepTopic> _topics = [
    // 1. Giấc ngủ trưa (Power Nap)
    _SleepTopic(
      id: 'power_nap',
      title: 'Giấc ngủ trưa (Power Nap)',
      keywords: const [
        _WeightedKeyword('power nap', 5),
        _WeightedKeyword('ngu trua', 5),
        _WeightedKeyword('giac ngu ngan', 4),
        _WeightedKeyword('ngu ngay', 3),
        _WeightedKeyword('nap', 2),
      ],
      responseBuilder: (_) =>
          '🌙 Về giấc ngủ trưa (Power Nap):\n\n'
          '1. Thời lượng vàng: 10 – 20 phút (khuyến nghị 15 – 20 phút). Tuyệt đối tránh ngủ quá 30 phút vì não bộ sẽ bước vào giai đoạn ngủ sâu (Slow-wave sleep), khi thức dậy sẽ gặp hiện tượng chuếnh choáng, mệt mỏi do quán tính giấc ngủ (Sleep Inertia).\n'
          '2. Khung giờ lý tưởng: Trong khoảng 12:30 – 13:30, cách giờ đi ngủ ban đêm ít nhất 6 tiếng để không làm suy giảm áp lực ngủ tự nhiên.\n'
          '3. Mẹo thực hành: Bạn có thể bật tính năng đếm ngược 15–20 phút trong tab "Giấc ngủ ngắn" của DCSleep để kiểm soát thời gian tối ưu nhé!',
    ),

    // 2. Kỹ thuật thở 4-7-8 & Giãn cơ (PMR)
    _SleepTopic(
      id: 'breathing_pmr',
      title: 'Kỹ thuật thở 4-7-8 & Giãn cơ (PMR)',
      keywords: const [
        _WeightedKeyword('4-7-8', 5),
        _WeightedKeyword('tho 4-7-8', 6),
        _WeightedKeyword('gian co luy tien', 5),
        _WeightedKeyword('gian co', 4),
        _WeightedKeyword('pmr', 4),
        _WeightedKeyword('tap tho', 3),
        _WeightedKeyword('hit tho', 3),
        _WeightedKeyword('pho giao cam', 4),
        _WeightedKeyword('thu gian', 2),
      ],
      responseBuilder: (_) =>
          '🌬️ Kỹ thuật thở 4-7-8 & Giãn cơ lũy tiến (PMR):\n\n'
          '1. Nhịp thở 4-7-8: Hít vào êm dịu bằng mũi trong 4 giây → Giữ hơi thở ổn định trong 7 giây → Thở ra từ từ bằng miệng tạo âm thanh nhẹ trong 8 giây. Thực hiện 4 chu kỳ liên tục để kích hoạt hệ thần kinh phó giao cảm, giúp nhịp tim chậm lại và cơ thể thư giãn sâu.\n'
          '2. Giãn cơ lũy tiến (PMR): Siết chặt từng nhóm cơ (bàn chân, bắp chân, đùi, vai) trong 5 giây rồi thả lỏng hoàn toàn trong 10 giây theo thứ tự từ dưới lên trên.\n'
          '3. Phương pháp này giúp cắt đứt chuỗi phản ứng căng thẳng thể chất và tạo đường dẫn tự nhiên vào giấc ngủ.',
    ),

    // 3. Vệ sinh Caffeine & Ăn uống
    _SleepTopic(
      id: 'caffeine_nutrition',
      title: 'Vệ sinh Caffeine & Ăn uống',
      keywords: const [
        _WeightedKeyword('ca phe', 5),
        _WeightedKeyword('caffeine', 5),
        _WeightedKeyword('tra sua', 4),
        _WeightedKeyword('nuoc tang luc', 4),
        _WeightedKeyword('do uong', 2),
        _WeightedKeyword('an uong', 2),
        _WeightedKeyword('an dem', 2),
        _WeightedKeyword('bua toi', 2),
        _WeightedKeyword('an toi', 1),
        _WeightedKeyword('tra', 2),
      ],
      responseBuilder: (_) =>
          '☕ Vệ sinh Caffeine & Chế độ dinh dưỡng trước giờ ngủ:\n\n'
          '1. Kiểm soát Caffeine: Tránh uống cà phê, trà đậm, trà sữa hoặc nước tăng lực sau 14:00 (Caffeine có thời gian bán hủy từ 5 – 7 tiếng trong cơ thể và phong tỏa thụ thể Adenosine gây cản trở cơn buồn ngủ tự nhiên).\n'
          '2. Bữa ăn tối & Ăn đêm: Không ăn quá no hoặc tiêu thụ thức ăn nhiều dầu mỡ, đồ cay nóng trong vòng 2 tiếng trước khi đi ngủ để phòng ngừa trào ngược dạ dày thực quản.\n'
          '3. Đồ uống bổ trợ: Bạn có thể dùng một ly nước ấm hoặc trà hoa cúc nhẹ (không chứa caffeine) trước khi ngủ 45 phút để làm dịu thần kinh.',
    ),

    // 4. Khó ngủ / Trằn trọc ban đêm (Quy tắc 20 phút)
    _SleepTopic(
      id: 'difficulty_sleeping',
      title: 'Khó ngủ / Trằn trọc (Quy tắc 20 phút)',
      keywords: const [
        _WeightedKeyword('tran troc', 5),
        _WeightedKeyword('kho ngu', 5),
        _WeightedKeyword('mat ngu', 5),
        _WeightedKeyword('khong ngu duoc', 5),
        _WeightedKeyword('quy tac 20 phut', 6),
        _WeightedKeyword('roi giuong', 5),
        _WeightedKeyword('thuc khuya', 3),
        _WeightedKeyword('20 phut', 3),
        _WeightedKeyword('den vang', 3),
      ],
      responseBuilder: (_) =>
          '💡 Xử lý tình trạng trằn trọc / Khó vào giấc (Quy tắc 20 phút):\n\n'
          '1. Quy tắc 20 phút: Nếu nằm trên giường quá 20 phút mà chưa thể ngủ được, hãy lập tức rời giường (ngồi dậy), di chuyển sang phòng khách hoặc không gian yên tĩnh khác.\n'
          '2. Thư giãn thụ động: Ngồi đọc sách giấy dưới ánh đèn vàng mờ hoặc nghe âm thanh thư giãn nhẹ. Tuyệt đối không nhìn đồng hồ đếm giờ để tránh kích hoạt cảm giác âu lo.\n'
          '3. Trở lại giường: Chỉ quay lại giường nằm khi mí mắt nặng trĩu và cảm giác buồn ngủ thực sự quay trở lại. Hãy rèn luyện cho não bộ liên kết: giường ngủ chỉ dành riêng cho giấc ngủ.',
    ),

    // 5. Ánh sáng xanh & Thiết bị điện tử
    _SleepTopic(
      id: 'blue_light',
      title: 'Ánh sáng xanh & Thiết bị điện tử',
      keywords: const [
        _WeightedKeyword('anh sang xanh', 6),
        _WeightedKeyword('luot dien thoai', 6),
        _WeightedKeyword('dien thoai', 4),
        _WeightedKeyword('man hinh', 4),
        _WeightedKeyword('thiet bi dien tu', 4),
        _WeightedKeyword('melatonin', 5),
        _WeightedKeyword('ipad', 3),
        _WeightedKeyword('may tinh', 3),
        _WeightedKeyword('tivi', 3),
      ],
      responseBuilder: (_) =>
          '📱 Ánh sáng xanh & Tác động của thiết bị số lên giấc ngủ:\n\n'
          '1. Cơ chế ức chế Melatonin: Ánh sáng xanh có bước sóng 450–480nm từ điện thoại, máy tính làm đánh lừa tuyến tùng rằng vẫn là ban ngày, ức chế tiết hormone Melatonin kéo dài từ 2–3 giờ.\n'
          '2. Quy tắc ngắt thiết bị: Ngừng sử dụng điện thoại và các màn hình phát sáng ít nhất 30 – 60 phút trước giờ đi ngủ dự kiến.\n'
          '3. Biện pháp thay thế: Bật chế độ ban đêm (Night Shift / Bedtime Mode) hoặc đeo kính chắn ánh sáng xanh nếu bắt buộc phải xử lý công việc muộn, và chuyển sang đọc sách giấy trước khi ngủ.',
    ),

    // 6. Nhịp sinh học & Chu kỳ 90 phút
    _SleepTopic(
      id: 'circadian_cycle',
      title: 'Nhịp sinh học & Chu kỳ 90 phút',
      keywords: const [
        _WeightedKeyword('chu ky 90 phut', 6),
        _WeightedKeyword('90 phut', 5),
        _WeightedKeyword('nhip sinh hoc', 6),
        _WeightedKeyword('social jetlag', 6),
        _WeightedKeyword('ngu bu', 5),
        _WeightedKeyword('circadian', 5),
        _WeightedKeyword('chu ky giac ngu', 5),
        _WeightedKeyword('rem', 3),
        _WeightedKeyword('nrem', 3),
      ],
      responseBuilder: (_) =>
          '⏰ Nhịp sinh học & Chu kỳ giấc ngủ 90 phút:\n\n'
          '1. Cấu trúc chu kỳ 90 phút: Mỗi chu kỳ giấc ngủ hoàn chỉnh kéo dài trung bình khoảng 90 phút (luân chuyển qua NREM 1-2-3 và REM). Thức dậy vào cuối chu kỳ sẽ giúp bạn tỉnh táo sảng khoái nhất.\n'
          '2. Tính toán thời lượng: Người trưởng thành cần khoảng 5 chu kỳ (tương đương 7.5 giờ) hoặc trong khoảng 7 – 9 giờ ngủ mỗi đêm.\n'
          '3. Tránh Social Jetlag (Lệch giờ sinh học xã hội): Hãy cố định giờ thức dậy cả trong tuần lẫn cuối tuần. Tránh ngủ bù quá 1.5 giờ vào cuối tuần để giữ nhịp sinh học cơ thể ổn định bền vững.',
    ),

    // 7. Căng thẳng / Overthinking / Deadline
    _SleepTopic(
      id: 'stress_overthinking',
      title: 'Căng thẳng / Overthinking / Deadline',
      keywords: const [
        _WeightedKeyword('brain dump', 6),
        _WeightedKeyword('overthinking', 6),
        _WeightedKeyword('deadline', 5),
        _WeightedKeyword('suy nghi nhieu', 4),
        _WeightedKeyword('stress', 4),
        _WeightedKeyword('ap luc', 4),
        _WeightedKeyword('cang thang', 4),
        _WeightedKeyword('lo lang', 3),
      ],
      responseBuilder: (_) =>
          '🧠 Giải tỏa căng thẳng & Hiện tượng suy nghĩ quá mức (Overthinking):\n\n'
          '1. Kỹ thuật Brain Dump (Xả rác tâm trí): Dành 5–10 phút trước khi ngủ 30 phút, viết toàn bộ những việc tồn đọng và kế hoạch ngày mai ra một cuốn sổ tay. Khi đã được lưu ra giấy, não bộ sẽ an tâm tắt chế độ xử lý căng thẳng.\n'
          '2. Hạ nhiệt cơ thể: Tắm hoặc ngâm chân nước ấm trước giờ ngủ 60–90 phút; khi ra khỏi nước, nhiệt độ cơ thể hạ xuống sẽ gửi tín hiệu kích hoạt cơn buồn ngủ.\n'
          '3. Kết hợp hơi thở: Áp dụng 4 chu kỳ thở 4-7-8 khi nằm trên giường để xoa dịu hệ thần kinh giao cảm.',
    ),

    // 8. Môi trường phòng ngủ & Đánh giá tiến độ nhật ký
    _SleepTopic(
      id: 'environment_progress',
      title: 'Môi trường phòng ngủ & Đánh giá nhật ký',
      keywords: const [
        _WeightedKeyword('phong ngu bao nhieu do', 6),
        _WeightedKeyword('phong ngu', 4),
        _WeightedKeyword('nhiet do', 4),
        _WeightedKeyword('moi truong', 4),
        _WeightedKeyword('danh gia tien do', 5),
        _WeightedKeyword('tien do giac ngu', 5),
        _WeightedKeyword('tien do', 4),
        _WeightedKeyword('danh gia', 3),
        _WeightedKeyword('nhat ky', 3),
        _WeightedKeyword('thoi quen', 2),
      ],
      responseBuilder: (sleepContext) {
        if (sleepContext != null && sleepContext.trim().isNotEmpty) {
          return '📊 Đánh giá thói quen & Dữ liệu nhật ký DCSleep:\n\n'
              '$sleepContext\n\n'
              'Lời khuyên chuyên môn: Việc duy trì khung giờ đi ngủ và thức giấc cố định là nền tảng quan trọng nhất để củng cố nhịp sinh học. Hãy tiếp tục ghi nhận nhật ký đều đặn để theo dõi tiến độ cải thiện chất lượng giấc ngủ nhé!';
        }
        return '🌿 Thiết lập môi trường phòng ngủ chuẩn khoa học:\n\n'
            '1. Nhiệt độ lý tưởng: Duy trì nhiệt độ phòng mát mẻ trong khoảng 20 – 24°C để hỗ trợ cơ thể hạ nhiệt sinh lý tự nhiên khi vào giấc.\n'
            '2. Độ tối: Giữ phòng tối hoàn toàn (sử dụng rèm cản sáng hoặc bịt mắt ngủ) nhằm kích thích tuyến tùng tiết Melatonin.\n'
            '3. Yên tĩnh: Hạn chế tối đa tiếng ồn; có thể sử dụng âm thanh trắng (White Noise) hoặc tiếng mưa nhẹ nếu môi trường sống nhiều tiếng ồn ngoài ý muốn.';
      },
    ),
  ];

  /// Phân tích prompt của người dùng và trả về hướng dẫn chuyên gia tương ứng.
  /// Hỗ trợ tham số sleepContext tùy chọn từ SleepProvider.
  static String getAdvice(String prompt, {String? sleepContext}) {
    final cleanInput = _normalizeInput(prompt);

    // Trường hợp đầu vào rỗng hoặc chỉ có khoảng trắng
    if (cleanInput.isEmpty) {
      return _buildFallback();
    }

    _SleepTopic? bestTopic;
    int maxScore = 0;

    for (final topic in _topics) {
      int topicScore = 0;
      for (final kw in topic.keywords) {
        final kwClean = _normalizeInput(kw.phrase);
        if (kwClean.isEmpty) continue;

        // Nếu cụm từ có chứa khoảng trắng hoặc dấu gạch nối (từ khóa đặc thù nhiều từ)
        if (kwClean.contains(' ') || kwClean.contains('-')) {
          if (cleanInput.contains(kwClean)) {
            topicScore += kw.weight;
          }
        } else {
          // Từ đơn lẻ: dùng RegExp word boundary để tránh khớp nhầm substring
          final pattern = RegExp('(?<=^|\\s)${RegExp.escape(kwClean)}(?=\\s|\$)', caseSensitive: false);
          if (pattern.hasMatch(cleanInput)) {
            topicScore += kw.weight;
          }
        }
      }

      if (topicScore > maxScore) {
        maxScore = topicScore;
        bestTopic = topic;
      }
    }

    if (bestTopic != null && maxScore > 0) {
      return '${bestTopic.responseBuilder(sleepContext)}\n\n$_disclaimer';
    }

    return _buildFallback();
  }

  static String _buildFallback() {
    return 'DCSleep hiện đang hoạt động ở chế độ ngoại tuyến. Trong chế độ này, tôi hỗ trợ tốt nhất các chủ đề: kỹ thuật thở 4-7-8, thời lượng ngủ trưa (Power nap), kiểm soát caffeine, mẹo khi khó ngủ, ánh sáng xanh, nhịp sinh học và thiết lập phòng ngủ. Bạn có thể chọn nhanh các câu hỏi gợi ý (Quick Chips) ở phía trên hoặc kết nối mạng để trò chuyện chi tiết hơn nhé!\n\n$_disclaimer';
  }

  /// Làm sạch đầu vào: bỏ dấu tiếng Việt, lọc dấu câu, gộp khoảng trắng thừa
  static String _normalizeInput(String raw) {
    if (raw.trim().isEmpty) return '';

    // 1. Loại bỏ dấu tiếng Việt bằng hàm chuẩn hóa có sẵn
    var text = SafetyGuardrails.removeDiacritics(raw.toLowerCase());

    // 2. Chuẩn hóa các biến thể của kỹ thuật thở 478 / 4 7 8 -> đồng bộ thành "4-7-8"
    text = text.replaceAll(RegExp(r'\b4\s*[-_ ]?\s*7\s*[-_ ]?\s*8\b'), '4-7-8');
    text = text.replaceAll('478', '4-7-8');

    // 3. Thay thế toàn bộ ký tự đặc biệt / dấu câu bằng khoảng trắng (chỉ giữ lại chữ cái, số và dấu gạch nối)
    text = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-]'), ' ');

    // 4. Gộp các khoảng trắng liên tiếp và trim
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
