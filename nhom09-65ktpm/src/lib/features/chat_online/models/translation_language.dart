/// Định nghĩa các ngôn ngữ được hỗ trợ trong Phân hệ Dịch thuật & Sổ tay từ vựng.
/// Hỗ trợ song ngữ 3 chiều: Tiếng Việt (VI) ⇄ Tiếng Anh (EN) ⇄ Tiếng Trung (ZH-CN).
enum TranslationLanguage {
  auto(
    code: 'auto',
    shortLabel: 'AUTO',
    displayName: 'Tự động nhận diện',
    nativeName: 'Auto Detect',
    flagEmoji: '🌐',
  ),
  vi(
    code: 'vi',
    shortLabel: 'VI',
    displayName: 'Tiếng Việt',
    nativeName: 'Tiếng Việt',
    flagEmoji: '🇻🇳',
  ),
  en(
    code: 'en',
    shortLabel: 'EN',
    displayName: 'Tiếng Anh',
    nativeName: 'English',
    flagEmoji: '🇬🇧',
  ),
  zhCn(
    code: 'zh-cn',
    shortLabel: 'ZH',
    displayName: 'Tiếng Trung',
    nativeName: '中文',
    flagEmoji: '🇨🇳',
  );

  final String code;
  final String shortLabel;
  final String displayName;
  final String nativeName;
  final String flagEmoji;

  const TranslationLanguage({
    required this.code,
    required this.shortLabel,
    required this.displayName,
    required this.nativeName,
    required this.flagEmoji,
  });

  /// Danh sách ngôn ngữ đích hợp lệ (không gồm chế độ tự động nhận diện)
  static const List<TranslationLanguage> selectableLanguages = [
    TranslationLanguage.vi,
    TranslationLanguage.en,
    TranslationLanguage.zhCn,
  ];

  /// Danh sách ngôn ngữ nguồn hợp lệ (bao gồm chế độ tự động nhận diện)
  static const List<TranslationLanguage> sourceOptions = [
    TranslationLanguage.auto,
    TranslationLanguage.vi,
    TranslationLanguage.en,
    TranslationLanguage.zhCn,
  ];

  /// Chuẩn hóa mã ngôn ngữ (ví dụ: 'zh', 'zh_CN', 'en-US', 'vi-VN') về enum chuẩn
  static TranslationLanguage fromCode(String? rawCode) {
    final normalized = (rawCode ?? '').trim().toLowerCase().replaceAll('_', '-');
    if (normalized.isEmpty || normalized == 'auto') {
      return TranslationLanguage.auto;
    }
    if (normalized == 'vi' || normalized.startsWith('vi-')) {
      return TranslationLanguage.vi;
    }
    if (normalized == 'en' || normalized.startsWith('en-')) {
      return TranslationLanguage.en;
    }
    if (normalized == 'zh' || normalized.startsWith('zh-')) {
      return TranslationLanguage.zhCn;
    }
    return TranslationLanguage.auto;
  }

  /// Trả về ngôn ngữ đích mặc định phù hợp với ngôn ngữ nguồn
  static TranslationLanguage defaultTargetFor(TranslationLanguage source) {
    return source == TranslationLanguage.vi
        ? TranslationLanguage.en
        : TranslationLanguage.vi;
  }

  /// Nhãn hiển thị ngắn gọn kèm cờ (ví dụ: "🇻🇳 Tiếng Việt")
  String get labelWithFlag => '$flagEmoji $displayName';
}
