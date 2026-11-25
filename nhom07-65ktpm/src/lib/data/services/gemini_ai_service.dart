import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiAIService {
  static final GeminiAIService instance = GeminiAIService._init();
  GeminiAIService._init();

  String _apiKey = '';

  void setApiKey(String key) {
    _apiKey = key;
  }

  Future<String> askSleepAssistant(String userPrompt, {String? sleepSummaryContext}) async {
    // If an API key is configured, call Gemini 1.5 Flash endpoint
    if (_apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        );

        final systemInstruction =
            'Bạn là chuyên gia tư vấn giấc ngủ khoa học của ứng dụng DCSleep. Hãy trả lời thân thiện, súc tích, bằng tiếng Việt. '
            'Tư vấn dựa trên các nguyên tắc vệ sinh giấc ngủ (Sleep Hygiene), kỹ thuật thở thư giãn, thời lượng ngủ trưa (Power nap 15-20p), '
            'hạn chế ánh sáng xanh. Luôn kèm lời khuyên: đây là gợi ý thói quen, không phải chẩn đoán y tế.';

        final promptWithContext = sleepSummaryContext != null
            ? '$systemInstruction\n\n[Dữ liệu nhật ký giấc ngủ của người dùng]: $sleepSummaryContext\n\n[Câu hỏi]: $userPrompt'
            : '$systemInstruction\n\n[Câu hỏi]: $userPrompt';

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': promptWithContext}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidateText = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (candidateText != null) {
            return candidateText.toString().trim();
          }
        }
      } catch (_) {
        // Fallback to local expert knowledge base if offline or network fails
      }
    }

    // Smart Local Expert Knowledge Base Fallback (Tuân thủ đề cương: chạy ngoại tuyến, không lỗi khi không có mạng)
    final lower = userPrompt.toLowerCase();

    if (lower.contains('ngủ trưa') || lower.contains('power nap') || lower.contains('nap')) {
      return '🌙 Về giấc ngủ trưa (Power Nap):\n\n'
          '1. Thời lượng lý tưởng: 10 - 20 phút. Tránh ngủ quá 30 phút vì dễ rơi vào giấc ngủ sâu (Slow-wave sleep), khi thức dậy sẽ bị mệt mỏi, choáng váng (hiện tượng Sleep Inertia).\n'
          '2. Thời điểm tốt nhất: Trong khoảng 12:30 - 13:30, cách giờ ngủ đêm ít nhất 6 tiếng.\n'
          '3. Bạn có thể sử dụng tab "Giấc ngủ ngắn" trong DCSleep để bấm đếm ngược 15-20 phút nhé!';
    } else if (lower.contains('khó ngủ') || lower.contains('mất ngủ') || lower.contains('thức khuya')) {
      return '💡 Gợi ý khắc phục khi khó ngủ hoặc thức khuya:\n\n'
          '1. Áp dụng quy tắc 20 phút: Nếu nằm trên giường 20 phút chưa ngủ được, hãy ngồi dậy, đọc sách giấy dưới ánh đèn vàng mờ cho đến khi thấy buồn ngủ.\n'
          '2. Kỹ thuật thở 4-7-8: Hít vào bằng mũi trong 4 giây, nín thở 7 giây, thở ra từ từ bằng miệng trong 8 giây (lặp lại 4 chu kỳ).\n'
          '3. Tắt điện thoại hoặc bật chế độ Giờ đi ngủ (Bedtime Mode) trước giờ ngủ 30 phút để tránh ánh sáng xanh ức chế Melatonin.\n\n'
          '*Lưu ý: Đây là lời khuyên xây dựng thói quen, không thay thế chẩn đoán y tế chuyên khoa.*';
    } else if (lower.contains('cà phê') || lower.contains('caffeine') || lower.contains('ăn')) {
      return '☕ Vệ sinh giấc ngủ về đồ ăn & thức uống:\n\n'
          '1. Caffeine: Tránh uống cà phê, trà đậm, nước tăng lực sau 14:00 (Caffeine có thời gian bán hủy từ 5 - 7 tiếng trong cơ thể).\n'
          '2. Bữa tối: Không ăn quá no trong vòng 2 tiếng trước khi đi ngủ để tránh trào ngược dạ dày.\n'
          '3. Có thể uống một ly nước ấm hoặc trà hoa cúc nhẹ để làm dịu thần kinh.';
    } else if (lower.contains('tiến độ') || lower.contains('nhật ký') || lower.contains('đánh giá')) {
      return '📊 Đánh giá thói quen dựa trên nhật ký của bạn:\n\n'
          'Việc duy trì khung giờ ngủ cố định (ví dụ 23:00 - 07:00) cả vào ngày trong tuần lẫn cuối tuần là yếu tố quan trọng nhất để ổn định nhịp sinh học (Circadian Rhythm). Hãy tiếp tục ghi nhận nhật ký đều đặn để theo dõi biểu đồ tiến độ nhé!';
    }

    return 'Chào bạn! Theo các nghiên cứu về vệ sinh giấc ngủ:\n\n'
        '• Người trưởng thành cần từ 7 - 9 giờ ngủ mỗi đêm để não bộ đào thải độc tố và phục hồi năng lượng.\n'
        '• Hãy giữ phòng ngủ mát mẻ (khoảng 20 - 24°C), tối hoàn toàn và yên tĩnh.\n'
        '• Bạn có thể hỏi tôi về: "kỹ thuật thở 4-7-8", "thời lượng ngủ trưa bao nhiêu", "cách bỏ thói quen lướt điện thoại ban đêm". Tôi luôn sẵn sàng hỗ trợ bạn!';
  }
}
