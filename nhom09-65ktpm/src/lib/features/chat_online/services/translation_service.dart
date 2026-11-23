import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/translation_result.dart';

/// Dịch vụ gọi API Dịch tức thì (Instant Translation Service)
/// Phân hệ Chat Thực Chiến 1-1 - Dự án BuddyTalk (Nhóm 09 - 65KTPM).
///
/// Phục vụ chức năng: Khi người dùng bấm nút "Dịch tức thì" bên cạnh bong bóng chat,
/// hàm sẽ gọi API và trả về bản dịch Anh - Việt siêu tốc (< 200ms) kèm cơ chế Cache bộ nhớ đệm.
class TranslationService {
  // Singleton pattern để dùng chung 1 instance trong toàn bộ ứng dụng
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// Bộ nhớ đệm (Cache) lưu trữ các câu đã dịch trong phiên làm việc
  /// Cấu trúc key: "$sourceLang-$targetLang:$text"
  final Map<String, TranslationResult> _translationCache = {};

  /// Thời gian tối đa chờ phản hồi API (Timeout: 5 giây)
  static const Duration _timeoutDuration = Duration(seconds: 5);

  /// URL Endpoint Google Translate công khai (Client GTX - Miễn phí 100%, không cần API Key)
  static const String _baseUrl = 'https://translate.googleapis.com/translate_a/single';

  /// Hàm cốt lõi: Dịch văn bản từ [from] sang [to]
  ///
  /// - [text]: Đoạn văn bản cần dịch
  /// - [from]: Mã ngôn ngữ gốc (mặc định 'auto' để tự nhận diện, hoặc 'en', 'vi')
  /// - [to]: Mã ngôn ngữ đích (mặc định 'vi' - tiếng Việt)
  Future<TranslationResult> translate({
    required String text,
    String from = 'auto',
    String to = 'vi',
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return TranslationResult.success(
        originalText: text,
        translatedText: '',
        sourceLanguage: from,
        targetLanguage: to,
      );
    }

    // 1. Kiểm tra trong bộ nhớ đệm (Cache) trước để tiết kiệm băng thông và hiển thị ngay
    final cacheKey = '$from-$to:$trimmedText';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    HttpClient? client;
    try {
      // 2. Chuẩn bị tham số Query Parameters
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'client': 'gtx',
          'sl': from,
          'tl': to,
          'dt': 't',
          'q': trimmedText,
        },
      );

      // 3. Thực hiện HTTP GET Request bằng dart:io HttpClient (không phụ thuộc bên thứ 3)
      client = HttpClient();
      client.connectionTimeout = _timeoutDuration;

      final request = await client.getUrl(uri).timeout(_timeoutDuration);
      request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(_timeoutDuration);

      if (response.statusCode != HttpStatus.ok) {
        return TranslationResult.failure(
          originalText: trimmedText,
          errorMessage: 'Máy chủ dịch phản hồi mã lỗi: ${response.statusCode}',
          sourceLanguage: from,
          targetLanguage: to,
        );
      }

      final responseBody = await response.transform(utf8.decoder).join();

      // 4. Phân tích cấu trúc dữ liệu JSON từ Google Translate
      // Cấu trúc trả về dạng mảng lồng nhau:
      // [[[ "Bản dịch", "Câu gốc", null, null, 1 ]], null, "en", ...]
      final dynamic decodedJson = jsonDecode(responseBody);

      if (decodedJson is List && decodedJson.isNotEmpty && decodedJson[0] is List) {
        final sentencesList = decodedJson[0] as List;
        final StringBuffer translatedBuffer = StringBuffer();

        for (final sentence in sentencesList) {
          if (sentence is List && sentence.isNotEmpty && sentence[0] != null) {
            translatedBuffer.write(sentence[0].toString());
          }
        }

        final detectedSourceLang = (decodedJson.length > 2 && decodedJson[2] is String)
            ? decodedJson[2] as String
            : from;

        final result = TranslationResult.success(
          originalText: trimmedText,
          translatedText: translatedBuffer.toString(),
          sourceLanguage: detectedSourceLang,
          targetLanguage: to,
        );

        // Lưu vào bộ nhớ đệm
        _translationCache[cacheKey] = result;
        return result;
      }

      return TranslationResult.failure(
        originalText: trimmedText,
        errorMessage: 'Định dạng dữ liệu dịch không hợp lệ.',
        sourceLanguage: from,
        targetLanguage: to,
      );
    } on TimeoutException {
      return TranslationResult.failure(
        originalText: trimmedText,
        errorMessage: 'Quá thời gian kết nối (Timeout). Vui lòng thử lại.',
        sourceLanguage: from,
        targetLanguage: to,
      );
    } on SocketException {
      return TranslationResult.failure(
        originalText: trimmedText,
        errorMessage: 'Không có kết nối mạng Internet.',
        sourceLanguage: from,
        targetLanguage: to,
      );
    } catch (e) {
      return TranslationResult.failure(
        originalText: trimmedText,
        errorMessage: 'Lỗi không xác định khi dịch: $e',
        sourceLanguage: from,
        targetLanguage: to,
      );
    } finally {
      client?.close();
    }
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Anh sang Tiếng Việt
  Future<TranslationResult> translateEnToVi(String text) {
    return translate(text: text, from: 'en', to: 'vi');
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Việt sang Tiếng Anh
  Future<TranslationResult> translateViToEn(String text) {
    return translate(text: text, from: 'vi', to: 'en');
  }

  /// Hàm thông minh cho phòng chat BuddyTalk:
  /// Tự động nhận diện ngôn ngữ của câu chat.
  /// Nếu người bạn nước ngoài chat tiếng Anh -> Dịch tức thì sang tiếng Việt.
  /// Nếu người dùng gõ tiếng Việt -> Dịch sang tiếng Anh để người bạn hiểu.
  Future<TranslationResult> translateAutoForChat(String text) async {
    // Bước đầu nhận diện qua 'auto' dịch sang 'vi'
    final firstTry = await translate(text: text, from: 'auto', to: 'vi');
    
    // Nếu nguồn đã là tiếng Việt thì chuyển sang dịch cho đối phương (sang 'en')
    if (firstTry.sourceLanguage.toLowerCase() == 'vi') {
      return translate(text: text, from: 'vi', to: 'en');
    }
    
    return firstTry;
  }

  /// Xóa bộ nhớ đệm khi đăng xuất hoặc xóa lịch sử chat
  void clearCache() {
    _translationCache.clear();
  }

  /// Xem số lượng câu đã được lưu cache
  int get cacheSize => _translationCache.length;
}

