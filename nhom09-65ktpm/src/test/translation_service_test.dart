import 'package:buddytalk/features/chat_online/models/translation_language.dart';
import 'package:buddytalk/features/chat_online/models/translation_result.dart';
import 'package:buddytalk/features/chat_online/services/translation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslationLanguage', () {
    test('fromCode chuan hoa cac ma ngon ngu Trung - Viet - Anh', () {
      expect(TranslationLanguage.fromCode('en'), TranslationLanguage.en);
      expect(TranslationLanguage.fromCode('en-US'), TranslationLanguage.en);
      expect(TranslationLanguage.fromCode('vi'), TranslationLanguage.vi);
      expect(TranslationLanguage.fromCode('vi_VN'), TranslationLanguage.vi);
      expect(TranslationLanguage.fromCode('zh'), TranslationLanguage.zhCn);
      expect(TranslationLanguage.fromCode('zh-CN'), TranslationLanguage.zhCn);
      expect(TranslationLanguage.fromCode('zh_cn'), TranslationLanguage.zhCn);
      expect(TranslationLanguage.fromCode('auto'), TranslationLanguage.auto);
      expect(TranslationLanguage.fromCode(''), TranslationLanguage.auto);
    });

    test('defaultTargetFor chon dung ngon ngu dich mac dinh', () {
      expect(
        TranslationLanguage.defaultTargetFor(TranslationLanguage.vi),
        TranslationLanguage.en,
      );
      expect(
        TranslationLanguage.defaultTargetFor(TranslationLanguage.en),
        TranslationLanguage.vi,
      );
      expect(
        TranslationLanguage.defaultTargetFor(TranslationLanguage.zhCn),
        TranslationLanguage.vi,
      );
    });
  });

  group('TranslationResult', () {
    test('toMap va fromMap giu nguyen ven thuoc tinh va trang thai cache', () {
      final original = TranslationResult.success(
        originalText: 'Practice makes perfect',
        translatedText: 'Có công mài sắt có ngày nên kim',
        sourceLanguage: 'en',
        targetLanguage: 'vi',
        fromCache: true,
      );

      final restored = TranslationResult.fromMap(original.toMap());
      expect(restored.originalText, 'Practice makes perfect');
      expect(restored.translatedText, 'Có công mài sắt có ngày nên kim');
      expect(restored.sourceLangEnum, TranslationLanguage.en);
      expect(restored.targetLangEnum, TranslationLanguage.vi);
      expect(restored.isSuccess, isTrue);
      expect(restored.fromCache, isTrue);
      expect(restored.languagePairLabel, 'EN → VI');
    });

    test('copyWith va failure hoat dong chinh xac', () {
      final failed = TranslationResult.failure(
        originalText: '你好',
        errorMessage: 'Timeout',
        sourceLanguage: 'zh-cn',
        targetLanguage: 'vi',
      );
      expect(failed.isSuccess, isFalse);
      expect(failed.translatedText, '你好');
      expect(failed.hasTranslation, isFalse);

      final updated = failed.copyWith(
        isSuccess: true,
        translatedText: 'Xin chào',
      );
      expect(updated.hasTranslation, isTrue);
      expect(updated.languagePairLabel, 'ZH → VI');
    });
  });

  group('TranslationService', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
      service.clearCache();
    });

    test('tra ve chuoi rong ngay lap tuc khi dau vao rong', () async {
      final res = await service.translate(text: '   ', from: 'en', to: 'vi');
      expect(res.isSuccess, isTrue);
      expect(res.translatedText, '');
      expect(service.cacheSize, 0);
    });

    test('tra ve ngay lap tuc khi ngon ngu nguon va dich trung nhau', () async {
      final res = await service.translate(
        text: 'Xin chào BuddyTalk',
        from: 'vi',
        to: 'vi',
      );
      expect(res.isSuccess, isTrue);
      expect(res.translatedText, 'Xin chào BuddyTalk');
      expect(res.isSameLanguage, isTrue);
    });

    test('doc du lieu tu In-memory Cache voi fromCache = true', () async {
      final seeded = TranslationResult.success(
        originalText: '你好',
        translatedText: 'Xin chào',
        sourceLanguage: 'zh-cn',
        targetLanguage: 'vi',
      );
      service.putCache(seeded);
      expect(service.cacheSize, 1);

      final cached = await service.translateZhToVi('你好');
      expect(cached.isSuccess, isTrue);
      expect(cached.translatedText, 'Xin chào');
      expect(cached.fromCache, isTrue);
    });

    test('nhan dien ky tu Tieng Trung va dau Tieng Viet chinh xac', () {
      expect(TranslationService.containsChineseCharacters('你好世界'), isTrue);
      expect(TranslationService.containsChineseCharacters('Hello'), isFalse);
      expect(
        TranslationService.containsVietnameseDiacritics('Luyện nói mỗi ngày'),
        isTrue,
      );
      expect(
        TranslationService.containsVietnameseDiacritics('Practice every day'),
        isFalse,
      );
    });
  });
}
