import 'dart:async';

import 'package:translator/translator.dart';

import '../models/translation_language.dart';
import '../models/translation_result.dart';

/// Dịch vụ gọi API Dịch tức thì (Instant Translation Service) đa nền tảng (Web & Mobile).
/// Phân hệ Trợ lý Dịch thuật Tức thì - Dự án BuddyTalk (Nhóm 09 - 65KTPM).
///
/// Sử dụng gói `translator` (`GoogleTranslator`) chạy thuần HTTP để tương thích
/// 100% trên cả Flutter Web (Chrome) lẫn Android/iOS, hỗ trợ cơ chế Cache bộ nhớ đệm.
class TranslationService {
  // Singleton pattern để dùng chung 1 instance trong toàn bộ ứng dụng
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();

  /// Bộ nhớ đệm (Cache) lưu trữ các câu đã dịch trong phiên làm việc.
  /// Cấu trúc key: "$sourceLang-$targetLang:$text"
  final Map<String, TranslationResult> _translationCache = {};

  /// Thời gian tối đa chờ phản hồi API (Timeout: 6 giây)
  static const Duration _timeoutDuration = Duration(seconds: 6);

  /// Hàm cốt lõi: Dịch văn bản từ [from] sang [to]
  ///
  /// - [text]: Đoạn văn bản cần dịch
  /// - [from]: Mã ngôn ngữ gốc (mặc định `'auto'` để tự nhận diện, hoặc `'en'`, `'vi'`, `'zh-cn'`)
  /// - [to]: Mã ngôn ngữ đích (mặc định `'vi'` - tiếng Việt)
  Future<TranslationResult> translate({
    required String text,
    String from = 'auto',
    String to = 'vi',
  }) async {
    final trimmedText = text.trim();
    final sourceCode = _normalizeApiCode(from, allowAuto: true);
    final targetCode = _normalizeApiCode(to, allowAuto: false);

    if (trimmedText.isEmpty) {
      return TranslationResult.success(
        originalText: text,
        translatedText: '',
        sourceLanguage: sourceCode,
        targetLanguage: targetCode,
      );
    }

    // Nếu ngôn ngữ nguồn và đích trùng nhau -> trả về luôn không cần gọi API
    if (sourceCode != 'auto' && sourceCode == targetCode) {
      return TranslationResult.success(
        originalText: trimmedText,
        translatedText: trimmedText,
        sourceLanguage: sourceCode,
        targetLanguage: targetCode,
      );
    }

    // 1. Kiểm tra bộ nhớ đệm (Cache) trước để tiết kiệm băng thông & phản hồi 0ms
    final cacheKey = '$sourceCode-$targetCode:$trimmedText';
    final cached = _translationCache[cacheKey];
    if (cached != null) {
      return cached.copyWith(fromCache: true);
    }

    try {
      // 2. Gọi API Google Translate qua package `translator` (tương thích Web & Android)
      final translation = await _translator
          .translate(trimmedText, from: sourceCode, to: targetCode)
          .timeout(_timeoutDuration);

      final detectedSource = TranslationLanguage.fromCode(
        translation.sourceLanguage.code,
      );
      final resolvedSourceCode = detectedSource == TranslationLanguage.auto
          ? sourceCode
          : detectedSource.code;

      final result = TranslationResult.success(
        originalText: trimmedText,
        translatedText: translation.text,
        sourceLanguage: resolvedSourceCode,
        targetLanguage: targetCode,
        fromCache: false,
      );

      // 3. Lưu vào bộ nhớ đệm
      _translationCache[cacheKey] = result;
      return result;
    } on TimeoutException {
      return TranslationResult.failure(
        originalText: trimmedText,
        errorMessage: 'Quá thời gian kết nối (Timeout). Vui lòng thử lại.',
        sourceLanguage: sourceCode,
        targetLanguage: targetCode,
      );
    } catch (e) {
      return TranslationResult.failure(
        originalText: trimmedText,
        errorMessage: 'Không thể dịch lúc này. Vui lòng kiểm tra kết nối mạng.',
        sourceLanguage: sourceCode,
        targetLanguage: targetCode,
      );
    }
  }

  /// Chuẩn hóa mã ngôn ngữ đầu vào để phù hợp với API `translator`
  String _normalizeApiCode(String rawCode, {required bool allowAuto}) {
    final lang = TranslationLanguage.fromCode(rawCode);
    if (!allowAuto && lang == TranslationLanguage.auto) {
      return TranslationLanguage.vi.code;
    }
    return lang.code;
  }

  /// Hàm tiện ích dùng enum [TranslationLanguage] cho UI chọn ngôn ngữ
  Future<TranslationResult> translateWithLanguages({
    required String text,
    TranslationLanguage from = TranslationLanguage.auto,
    TranslationLanguage to = TranslationLanguage.vi,
  }) {
    return translate(text: text, from: from.code, to: to.code);
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Anh sang Tiếng Việt
  Future<TranslationResult> translateEnToVi(String text) {
    return translate(
      text: text,
      from: TranslationLanguage.en.code,
      to: TranslationLanguage.vi.code,
    );
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Việt sang Tiếng Anh
  Future<TranslationResult> translateViToEn(String text) {
    return translate(
      text: text,
      from: TranslationLanguage.vi.code,
      to: TranslationLanguage.en.code,
    );
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Trung (Giản thể) sang Tiếng Việt
  Future<TranslationResult> translateZhToVi(String text) {
    return translate(
      text: text,
      from: TranslationLanguage.zhCn.code,
      to: TranslationLanguage.vi.code,
    );
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Việt sang Tiếng Trung (Giản thể)
  Future<TranslationResult> translateViToZh(String text) {
    return translate(
      text: text,
      from: TranslationLanguage.vi.code,
      to: TranslationLanguage.zhCn.code,
    );
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Anh sang Tiếng Trung
  Future<TranslationResult> translateEnToZh(String text) {
    return translate(
      text: text,
      from: TranslationLanguage.en.code,
      to: TranslationLanguage.zhCn.code,
    );
  }

  /// Hàm tiện ích: Dịch câu chat từ Tiếng Trung sang Tiếng Anh
  Future<TranslationResult> translateZhToEn(String text) {
    return translate(
      text: text,
      from: TranslationLanguage.zhCn.code,
      to: TranslationLanguage.en.code,
    );
  }

  /// Kiểm tra nhanh câu có chứa ký tự Tiếng Trung (CJK Unified Ideographs)
  static bool containsChineseCharacters(String text) {
    return RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
  }

  /// Kiểm tra nhanh câu có chứa dấu thanh/chữ cái đặc trưng Tiếng Việt
  static bool containsVietnameseDiacritics(String text) {
    return RegExp(
      r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ]',
    ).hasMatch(text);
  }

  /// Hàm thông minh cho phòng chat BuddyTalk:
  /// Tự động nhận diện ngôn ngữ của câu chat.
  /// - Nếu người bạn nước ngoài chat Tiếng Anh hoặc Tiếng Trung -> Dịch sang Tiếng Việt.
  /// - Nếu người dùng gõ Tiếng Việt -> Dịch sang [preferredForeignLang] (mặc định Tiếng Anh).
  Future<TranslationResult> translateAutoForChat(
    String text, {
    TranslationLanguage preferredForeignLang = TranslationLanguage.en,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return translate(text: text, from: 'auto', to: 'vi');
    }

    final targetForeign = preferredForeignLang == TranslationLanguage.vi ||
            preferredForeignLang == TranslationLanguage.auto
        ? TranslationLanguage.en
        : preferredForeignLang;

    if (containsChineseCharacters(trimmed)) {
      return translateZhToVi(trimmed);
    }

    if (containsVietnameseDiacritics(trimmed)) {
      return translate(
        text: trimmed,
        from: TranslationLanguage.vi.code,
        to: targetForeign.code,
      );
    }

    final firstTry = await translate(
      text: trimmed,
      from: TranslationLanguage.auto.code,
      to: TranslationLanguage.vi.code,
    );

    final isUnchangedVi = firstTry.isSuccess &&
        firstTry.sourceLangEnum == TranslationLanguage.auto &&
        firstTry.translatedText.trim().toLowerCase() == trimmed.toLowerCase();

    if (firstTry.sourceLangEnum == TranslationLanguage.vi || isUnchangedVi) {
      return translate(
        text: trimmed,
        from: TranslationLanguage.vi.code,
        to: targetForeign.code,
      );
    }

    return firstTry;
  }

  /// Lưu sẵn một kết quả vào Cache (hữu ích khi kiểm thử hoặc đồng bộ trước)
  void putCache(TranslationResult result) {
    if (!result.isSuccess) return;
    final key =
        '${result.sourceLangEnum.code}-${result.targetLangEnum.code}:${result.originalText.trim()}';
    _translationCache[key] = result;
  }

  /// Xóa bộ nhớ đệm khi đăng xuất hoặc xóa lịch sử chat
  void clearCache() {
    _translationCache.clear();
  }

  /// Xem số lượng câu đã được lưu cache
  int get cacheSize => _translationCache.length;
}
