import 'package:chailish/core/contracts/lesson_repository.dart';
import 'package:chailish/core/contracts/models/lesson.dart';
import 'package:chailish/features/pronunciation/engine/cedict_pinyin_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLessonRepo implements LessonRepository {
  @override
  Future<List<Lesson>> lessons() async => [];

  @override
  Future<Lesson?> lessonById(int id) async => null;

  @override
  Future<Lesson?> lessonByCode(String code) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CedictPinyinService service;

  setUp(() {
    service = CedictPinyinService(_FakeLessonRepo());
  });

  group('CedictPinyinService toPinyin & normalization', () {
    test('converts basic words accurately', () async {
      final p1 = await service.toPinyin('你好');
      expect(p1, 'nǐ hǎo');

      final p2 = await service.toPinyin('谢谢');
      expect(p2, 'xiè xie');

      final p3 = await service.toPinyin('老师');
      expect(p3, 'lǎo shī');
    });

    test('normalizes numbers and punctuation', () async {
      final p = await service.toPinyin('你好！123');
      expect(p, 'nǐ hǎo yī èr sān');
    });

    test('converts words outside lessons using CC-CEDICT compact', () async {
      // Các từ ngoài bài học 1-3
      final p1 = await service.toPinyin('猫');
      expect(p1, 'māo');

      final p2 = await service.toPinyin('狗');
      expect(p2, 'gǒu');

      final p3 = await service.toPinyin('喝茶');
      expect(p3, 'hē chá');

      final p4 = await service.toPinyin('苹果');
      expect(p4, 'píng guǒ');

      final p5 = await service.toPinyin('火车');
      expect(p5, 'huǒ chē');
    });

    test('falls back to character-by-character lookup for unknown compounds', () async {
      // Cụm từ ghép chưa có trong từ điển: tra theo từng chữ đơn "看" + "猫"
      final p = await service.toPinyin('看猫');
      expect(p, 'kàn māo');
    });
  });

  group('CedictPinyinService tone sandhi rules (biến điệu)', () {
    test('3-3 sandhi: first tone 3 changes to tone 2 when applySandhi is true', () async {
      // Without sandhi
      final raw = await service.toPinyin('你好', applySandhi: false);
      expect(raw, 'nǐ hǎo');

      // With sandhi
      final sandhi = await service.toPinyin('你好', applySandhi: true);
      expect(sandhi, 'ní hǎo');

      final s2 = await service.toPinyin('水饺', applySandhi: true);
      expect(s2, 'shuí jiǎo');
    });

    test('bu sandhi: 不 before tone 4 becomes bú, between duplicate verbs becomes bu', () async {
      // Đứng trước thanh 4: bú
      final b1 = await service.toPinyin('不是', applySandhi: true);
      expect(b1, 'bú shì');

      // Đứng trước thanh khác (thanh 1, 2, 3): giữ nguyên bù
      final b2 = await service.toPinyin('不行', applySandhi: true);
      expect(b2.split(' ').first, 'bù');

      // Ở giữa động từ lặp lại: bu (thanh nhẹ)
      final b3 = await service.toPinyin('想不想', applySandhi: true);
      expect(b3, 'xiǎng bu xiǎng');
    });

    test('yi sandhi: 一 before tone 4 becomes yí, before tone 1-3 becomes yì, between verbs becomes yi', () async {
      // Đứng trước thanh 4: yí
      final y1 = await service.toPinyin('一共', applySandhi: true);
      expect(y1, 'yí gòng');

      // Đứng trước thanh 1: yì
      final y2 = await service.toPinyin('一天', applySandhi: true);
      expect(y2, 'yì tiān');

      // Ở giữa động từ lặp lại: yi
      final y3 = await service.toPinyin('看一看', applySandhi: true);
      expect(y3, 'kàn yi kàn');
    });
  });

  group('Helper methods: tones & tone stripping', () {
    test('getToneNumber extracts correct tone 1..5', () {
      expect(service.getToneNumber('mā'), 1);
      expect(service.getToneNumber('má'), 2);
      expect(service.getToneNumber('mǎ'), 3);
      expect(service.getToneNumber('mà'), 4);
      expect(service.getToneNumber('ma'), 5);
    });

    test('removeToneMarks strips all diacritics', () {
      expect(service.removeToneMarks('nǐ'), 'ni');
      expect(service.removeToneMarks('hǎo'), 'hao');
      expect(service.removeToneMarks('lǚ'), 'lü');
    });
  });
}
