import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chailish/core/contracts/lesson_repository.dart';
import 'package:chailish/core/contracts/models/lesson.dart';
import 'package:chailish/core/contracts/models/pronunciation.dart';
import 'package:chailish/core/contracts/pronunciation_scorer.dart';
import 'package:chailish/core/network/api_client.dart';
import 'package:chailish/core/storage/secure_storage_service.dart';
import 'package:chailish/features/pronunciation/engine/cedict_pinyin_service.dart';
import 'package:chailish/features/pronunciation/engine/hybrid_pronunciation_scorer.dart';
import 'package:chailish/features/pronunciation/engine/offline_pronunciation_engine.dart';

class _FakeLessonRepository implements LessonRepository {
  @override
  Future<List<Lesson>> lessons() async => [];

  @override
  Future<Lesson?> lessonById(int id) async => null;

  @override
  Future<Lesson?> lessonByCode(String code) async => null;
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(const FlutterSecureStorage());

  @override
  Future<String?> getToken() async => 'fake_token';
}

class _MockApiClient extends ApiClient {
  final Future<dynamic> Function(
    String endpoint,
    Map<String, String>? fields,
    String fileField,
    String filePath,
  )? onPostMultipart;

  _MockApiClient({this.onPostMultipart})
      : super(storage: _FakeSecureStorageService());

  @override
  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    required String fileField,
    required String filePath,
    bool requireAuth = true,
  }) async {
    if (onPostMultipart != null) {
      return onPostMultipart!(endpoint, fields, fileField, filePath);
    }
    throw ApiException(503, 'Azure Speech key not configured');
  }
}

void main() {
  group('Module Cham Phat Am Tieng Trung - Unit Test (#16)', () {
    late OfflinePronunciationEngine scorer;

    setUp(() {
      scorer = OfflinePronunciationEngine();
    });

    test('1. Tach am tiet pinyin co dau chuan xac', () {
      final haoSyl = splitPinyin('hǎo');
      expect(haoSyl.initial, 'h');
      expect(haoSyl.finalPart, 'ao');
      expect(haoSyl.tone, 3);

      final niSyl = splitPinyin('nǐ');
      expect(niSyl.initial, 'n');
      expect(niSyl.finalPart, 'i');
      expect(niSyl.tone, 3);

      final zhongSyl = splitPinyin('zhōng');
      expect(zhongSyl.initial, 'zh');
      expect(zhongSyl.finalPart, 'ong');
      expect(zhongSyl.tone, 1);
    });

    test('2. Cham diem cau doc chuan tra ve diem cao (>80)', () async {
      final res = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
      );

      expect(res.overall, greaterThanOrEqualTo(80));
      expect(res.syllables.length, 2);
      expect(res.syllables[0].status, SyllableStatus.ok);
      expect(res.syllables[1].status, SyllableStatus.ok);
    });

    test('3. Phat hien va tinh diem phan hoi day du 4 thanh phan', () async {
      final res = await scorer.assess(
        referenceHanzi: '谢谢',
        referencePinyin: 'xiè xie',
      );

      expect(res.accuracy, greaterThan(0));
      expect(res.tone, greaterThan(0));
      expect(res.fluency, greaterThan(0));
      expect(res.completeness, 100.0);
    });

    test('4. Kiem tra bien dieu 2 thanh 3 (3+3 -> 2+3)', () {
      final p1 = splitPinyin('nǐ');
      final p2 = splitPinyin('hǎo');
      expect(p1.tone, 3);
      expect(p2.tone, 3);
    });

    test('5. Kiem tra tach thanh mau zh, ch, sh dung quy chuan', () {
      final zh = splitPinyin('zhōng');
      final ch = splitPinyin('chī');
      final sh = splitPinyin('shū');

      expect(zh.initial, 'zh');
      expect(ch.initial, 'ch');
      expect(sh.initial, 'sh');
    });

    test('6. Kiem tra am tiet thanh nhe tone = 5', () {
      final ma = splitPinyin('ma');
      final de = splitPinyin('de');

      expect(ma.tone, 5);
      expect(de.tone, 5);
    });

    test('7. Phat hien bat loi thanh dieu khi doc sai dau (ni hao, ni hao, ni hao)', () async {
      // Test ni háo: sai ca 2 thanh (thanh 5 + thanh 2 so voi thanh 3 + thanh 3)
      final resNiHao = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
        recognizedPinyin: 'ni háo',
      );
      expect(resNiHao.overall, lessThan(80));
      expect(resNiHao.syllables[0].errors.contains(PronunciationError.tone), isTrue);
      expect(resNiHao.syllables[1].errors.contains(PronunciationError.tone), isTrue);

      // Test nĩ hào: hào sai thanh 4 so voi thanh 3
      final resNiHao4 = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
        recognizedPinyin: 'nĩ hào',
      );
      expect(resNiHao4.syllables[1].errors.contains(PronunciationError.tone), isTrue);
      expect(resNiHao4.syllables[1].status, SyllableStatus.error);

      // Test nỉ hao: hao thieu dau (thanh 5 so voi thanh 3)
      final resNiHao5 = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
        recognizedPinyin: 'nỉ hao',
      );
      expect(resNiHao5.syllables[1].errors.contains(PronunciationError.tone), isTrue);
      expect(resNiHao5.syllables[1].status, SyllableStatus.error);
    });
  });

  group('CedictPinyinService - Quy tac bien dieu bu / yi / 3+3 (#12)', () {
    late CedictPinyinService pinyinService;

    setUp(() {
      pinyinService = CedictPinyinService(_FakeLessonRepository());
    });

    test('Chuan hoa chu so va bo dau cau', () {
      expect(CedictPinyinService.normalize('123，你好！'), '一二三你好');
      expect(CedictPinyinService.normalize('  0, 5 ?  '), '零 五');
    });

    test('Bien dieu 3+3 (hai thanh 3 di lien nhau doi thanh dau thanh thanh 2)', () async {
      // Khong bat sandhi: giu nguyen thanh goc
      final raw = await pinyinService.toPinyin('你好', applySandhi: false);
      expect(raw, 'nǐ hǎo');

      // Bat sandhi: nǐ -> ní
      final sandhi = await pinyinService.toPinyin('你好', applySandhi: true);
      expect(sandhi, 'ní hǎo');
    });

    test('Bien dieu 不 (bu): truoc thanh 4 bien thanh bu, kep giua hai tu bien thanh thanh nhe', () async {
      // Không bật sandhi: '不' = 'bù'
      final raw = await pinyinService.toPinyin('不是', applySandhi: false);
      expect(raw, 'bù shì');

      // Bật sandhi: '不是' -> 'bú shì' (trước thanh 4)
      final sandhi4 = await pinyinService.toPinyin('不是', applySandhi: true);
      expect(sandhi4, 'bú shì');

      // '好不好' -> 'hǎo bu hǎo' (đứng giữa cấu trúc lặp A-不-A)
      final sandhiRep = await pinyinService.toPinyin('好不好', applySandhi: true);
      expect(sandhiRep, 'hǎo bu hǎo');
    });

    test('Bien dieu 一 (yi): truoc thanh 1/2/3 bien thanh yi, truoc thanh 4 bien thanh yi', () async {
      // Trước thanh 1: '一天' -> 'yì tiān'
      final yiTian = await pinyinService.toPinyin('一天', applySandhi: true);
      expect(yiTian, 'yì tiān');

      // Trước thanh 3: '一起' -> 'yì qǐ'
      final yiQi = await pinyinService.toPinyin('一起', applySandhi: true);
      expect(yiQi, 'yì qǐ');

      // Đứng giữa cấu trúc lặp A-一-A: '看一看' -> 'kàn yi kàn'
      final kanYiKan = await pinyinService.toPinyin('看一看', applySandhi: true);
      expect(kanYiKan, 'kàn yi kàn');
    });
  });

  group('HybridPronunciationScorer - Fallback giua Online va Offline (#14)', () {
    late Directory tempDir;
    late File testWavFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('chailish_test_audio_');
      testWavFile = File('${tempDir.path}/sample.wav')..writeAsBytesSync([0x52, 0x49, 0x46, 0x46]);
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Khi mode la offlineOnly, cham truc tiep qua offline engine', () async {
      final scorer = HybridPronunciationScorer(
        getScoringMode: () => ScoringMode.offlineOnly,
      );

      final res = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
        recognizedText: '你好',
        recording: Recording(path: testWavFile.path, duration: const Duration(seconds: 1)),
      );

      expect(res.source, ScoringSource.offline);
      expect(res.overall, greaterThanOrEqualTo(80));
    });

    test('Khi mode la preferOnline nhung khong co file audio (path null), tu dong fallback offline', () async {
      final scorer = HybridPronunciationScorer(
        getScoringMode: () => ScoringMode.preferOnline,
      );

      final res = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
        recognizedText: '你好',
        recording: const Recording(path: null, duration: Duration(seconds: 1)),
      );

      expect(res.source, ScoringSource.offline);
    });

    test('Khi mode la preferOnline nhung server gap loi/503/mat ket noi, tu dong fallback sang offline engine', () async {
      final mockClient = _MockApiClient(
        onPostMultipart: (endpoint, fields, fileField, filePath) async {
          throw ApiException(503, 'Azure Speech Key missing');
        },
      );

      final scorer = HybridPronunciationScorer(
        getScoringMode: () => ScoringMode.preferOnline,
        apiClient: mockClient,
      );

      final res = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
        recognizedText: '你好',
        recording: Recording(path: testWavFile.path, duration: const Duration(seconds: 1)),
      );

      // Phai fallback an toan ve offline, khong gay crash app
      expect(res.source, ScoringSource.offline);
      expect(res.overall, greaterThanOrEqualTo(80));
    });

    test('Khi mode la preferOnline va server tra ket qua Azure hop le, tra ve ket qua online', () async {
      final mockClient = _MockApiClient(
        onPostMultipart: (endpoint, fields, fileField, filePath) async {
          return {
            'overall': 92.5,
            'accuracy': 95.0,
            'fluency': 90.0,
            'completeness': 100.0,
            'tone': 92.0,
            'recognized_text': '你好',
            'recognized_pinyin': 'nǐ hǎo',
            'source': 'online',
            'syllables': [
              {
                'hanzi': '你',
                'expected': {'initial': 'n', 'final': 'i', 'tone': 3},
                'actual': {'initial': 'n', 'final': 'i', 'tone': 3},
                'score': 95.0,
                'status': 'ok',
                'errors': [],
              },
              {
                'hanzi': '好',
                'expected': {'initial': 'h', 'final': 'ao', 'tone': 3},
                'actual': {'initial': 'h', 'final': 'ao', 'tone': 3},
                'score': 90.0,
                'status': 'ok',
                'errors': [],
              },
            ],
          };
        },
      );

      final scorer = HybridPronunciationScorer(
        getScoringMode: () => ScoringMode.preferOnline,
        apiClient: mockClient,
      );

      final res = await scorer.assess(
        referenceHanzi: '你好',
        referencePinyin: 'nǐ hǎo',
        recording: Recording(path: testWavFile.path, duration: const Duration(seconds: 1)),
      );

      expect(res.source, ScoringSource.online);
      expect(res.overall, 92.5);
      expect(res.syllables.length, 2);
      expect(res.syllables[0].expected.initial, 'n');
    });
  });
}
