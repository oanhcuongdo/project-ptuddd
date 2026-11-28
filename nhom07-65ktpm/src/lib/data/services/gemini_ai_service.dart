import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dcsleep/data/models/ai_message_model.dart';
import 'package:dcsleep/data/services/ai_service.dart';

/// Dịch vụ gọi Gemini REST API (tách biệt hoàn toàn khỏi OfflineSleepEngine).
/// Sử dụng header `x-goog-api-key`, hỗ trợ inject `http.Client` để kiểm thử bằng `MockClient`,
/// timeout 10 giây và chuẩn hóa lịch sử hội thoại `contents` tránh lỗi 400 Bad Request.
class GeminiAIService implements AIService {
  static final GeminiAIService instance = GeminiAIService();

  static const List<String> _fallbackModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash',
    'gemini-3.8-flash',
  ];

  static const String _baseSystemInstruction = '''
[VAI TRÒ VÀ TÍNH CÁCH]:
Bạn là Chuyên gia Tư vấn Giấc ngủ Khoa học của ứng dụng DCSleep. Hãy trả lời ấm áp, thấu cảm, khoa học, súc tích bằng tiếng Việt. Độ dài câu trả lời lý tưởng dưới 200 từ.

[PHẠM VI TRI THỨC ĐƯỢC PHÉP TƯ VẤN]:
1. Nguyên tắc Vệ sinh Giấc ngủ (Sleep Hygiene): Ánh sáng, nhiệt độ phòng ngủ (20-24°C), kiểm soát caffeine (tránh sau 14h), hạn chế ánh sáng xanh từ thiết bị số.
2. Nhịp sinh học (Circadian Rhythm): Quy tắc thức ngủ đều đặn, chu kỳ giấc ngủ 90 phút (REM & NREM).
3. Kỹ thuật thư giãn hỗ trợ vào giấc: Kỹ thuật thở 4-7-8, giãn cơ lũy tiến (PMR), quy tắc 20 phút rời giường khi mất ngủ.
4. Quản lý giấc ngủ ngắn (Power Nap): 10 - 20 phút buổi trưa (12:30 - 13:30), tránh ngủ quá 30 phút gây quán tính giấc ngủ (Sleep Inertia).

[RANH GIỚI VÀ QUY TẮC BẮT BUỘC]:
- KHÔNG BAO GIỜ đưa ra chẩn đoán y khoa hoặc kê đơn, hướng dẫn liều lượng bất kỳ loại thuốc ngủ/thuốc an thần nào.
- Luôn kết thúc bằng lưu ý ngắn: Lời khuyên mang tính chất hỗ trợ xây dựng lối sống khoa học, không thay thế chỉ định y tế.''';

  final http.Client _client;
  final Duration _timeout;
  String _apiKey = '';

  GeminiAIService({
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 8);

  @override
  void setApiKey(String key) {
    _apiKey = key.trim();
  }

  @override
  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  @override
  Future<String> askAssistant({
    required String prompt,
    String? sleepContext,
    List<AIMessageModel> history = const [],
  }) async {
    if (!hasApiKey) {
      throw AIServiceException('Chưa cấu hình API Key');
    }

    AIServiceException? lastException;

    for (final model in _fallbackModels) {
      final sw = Stopwatch()..start();
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      );

      final generationConfig = <String, dynamic>{
        'temperature': 0.7,
        'topP': 0.95,
        'maxOutputTokens': 1024,
        if (!model.contains('lite'))
          'thinkingConfig': {
            'thinkingBudget': 0,
          },
      };

      final payload = {
        'systemInstruction': {
          'parts': [
            {'text': _buildSystemInstruction(sleepContext)},
          ],
        },
        'contents': buildContentsPayload(
          history: history,
          currentPrompt: prompt,
        ),
        'generationConfig': generationConfig,
      };

      try {
        final response = await _client
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _apiKey,
              },
              body: jsonEncode(payload),
            )
            .timeout(_timeout);

        sw.stop();
        final responseBody = utf8.decode(response.bodyBytes);

        if (response.statusCode == 200) {
          debugPrint(
            '[GeminiAIService] Thành công với $model (${sw.elapsedMilliseconds}ms)',
          );
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final firstCandidate = candidates.first as Map<String, dynamic>?;
            final content = firstCandidate?['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            final firstPart = parts != null && parts.isNotEmpty ? parts.first : null;
            final text = firstPart is Map<String, dynamic>
                ? firstPart['text']?.toString().trim()
                : null;

            if (text != null && text.isNotEmpty) {
              return text;
            }
          }
        }

        debugPrint(
          '[GeminiAIService] Model $model lỗi (${response.statusCode}): $responseBody',
        );
        if (response.statusCode == 400) {
          debugPrint(
            '[GeminiAIService] Payload lỗi 400: ${jsonEncode(payload)}',
          );
        }
        lastException = AIServiceException(
          responseBody,
          statusCode: response.statusCode,
        );

        // Nếu quá tải (503) hoặc chạm rate-limit (429), tự động thử model kế tiếp
        if (response.statusCode == 503 || response.statusCode == 429) {
          continue;
        }

        // Lỗi xác thực hoặc cú pháp (400, 401, 403, 404...) thì dừng ngay
        throw lastException;
      } on AIServiceException {
        rethrow;
      } on TimeoutException catch (e) {
        debugPrint('[GeminiAIService] Model $model timeout > ${_timeout.inSeconds}s, thử model kế tiếp');
        lastException = AIServiceException(
          'Quá thời gian chờ phản hồi từ máy chủ AI',
          cause: e,
        );
        continue;
      } on SocketException catch (e) {
        throw AIServiceException('Mất kết nối Internet: $e', cause: e);
      } catch (e) {
        lastException = AIServiceException('Lỗi kết nối dịch vụ AI: $e', cause: e);
        continue;
      }
    }

    throw lastException ?? AIServiceException('Dịch vụ AI tạm thời không khả dụng');
  }

  String _buildSystemInstruction(String? sleepContext) {
    if (sleepContext == null || sleepContext.trim().isEmpty) {
      return _baseSystemInstruction;
    }
    return '$_baseSystemInstruction\n\n[DỮ LIỆU THỰC TẾ TỪ DCSLEEP HIỆN TẠI]:\n${sleepContext.trim()}';
  }

  /// Chuẩn hóa mảng `contents` cho Gemini REST API:
  /// 1. Nạp lịch sử từ `history`.
  /// 2. Nối `currentPrompt` (`role: user`) vào cuối TRƯỚC khi khử trùng lặp.
  /// 3. Cắt cửa sổ trượt tối đa 7 tin nhắn gần nhất.
  /// 4. Bỏ qua các tin nhắn `role: model` ở đầu mảng.
  /// 5. Khử trùng lặp các role đứng liền nhau (giữ phần tử mới hơn).
  List<Map<String, dynamic>> buildContentsPayload({
    List<AIMessageModel> history = const [],
    required String currentPrompt,
  }) {
    final rawContents = <Map<String, dynamic>>[];

    for (final msg in history) {
      if (msg.text.trim().isEmpty) continue;
      rawContents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text},
        ],
      });
    }

    rawContents.add({
      'role': 'user',
      'parts': [
        {'text': currentPrompt},
      ],
    });

    final windowed = rawContents.length > 7
        ? rawContents.sublist(rawContents.length - 7)
        : List<Map<String, dynamic>>.from(rawContents);

    while (windowed.isNotEmpty && windowed.first['role'] == 'model') {
      windowed.removeAt(0);
    }

    final deduped = <Map<String, dynamic>>[];
    for (final item in windowed) {
      if (deduped.isNotEmpty && deduped.last['role'] == item['role']) {
        deduped.removeLast();
      }
      deduped.add(item);
    }

    return deduped;
  }
}
