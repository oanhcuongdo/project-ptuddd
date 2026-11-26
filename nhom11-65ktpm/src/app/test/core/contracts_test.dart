import 'dart:convert';
import 'dart:io';

import 'package:chailish/core/contracts/contracts.dart';
import 'package:chailish/core/network/api_client.dart';
import 'package:chailish/core/storage/secure_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dữ liệu bài mẫu', () {
    test('assets/dev/lessons trùng với nhom11-65ktpm/data/lessons (chạy scripts/sync_dev_data.sh nếu lệch)', () {
      final data = Directory('../../data/lessons');
      final files = data.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      expect(files, isNotEmpty);
      for (final f in files) {
        final rel = f.path.substring(data.path.length);
        final copy = File('assets/dev/lessons$rel');
        expect(copy.existsSync(), isTrue, reason: 'thiếu bản sao $rel trong assets/dev/lessons');
        expect(jsonDecode(copy.readAsStringSync()), jsonDecode(f.readAsStringSync()), reason: '$rel bị lệch');
      }
    });

    test('AssetLessonRepository đọc đủ bài, id theo thứ tự như seed_dev', () async {
      final repo = AssetLessonRepository();
      final lessons = await repo.lessons();
      expect(lessons.length, greaterThanOrEqualTo(3));
      expect(lessons.map((l) => l.id), [for (var i = 1; i <= lessons.length; i++) i]);
      final first = lessons.first;
      expect(first.code, 'hsk1-greetings-01');
      expect(first.words.first.hanzi, '你好');
      expect(first.words.first.key, 'hsk1-greetings-01/ni-hao');
      expect(first.grammarPoints, isNotEmpty);
      expect((await repo.lessonByCode('hsk1-family-02'))?.id, 2);
    });

    test('mẹo phát âm mẫu đọc được', () async {
      final raw = jsonDecode(await rootBundle.loadString('assets/data/pronunciation_tips.json')) as Map<String, dynamic>;
      final tips = [for (final t in raw['tips'] as List) PronunciationTip.fromJson(t as Map<String, dynamic>)];
      expect(tips.map((t) => t.sound), containsAll(['zh', 'tone3']));
    });
  });

  group('Sự kiện học tập', () {
    test('toJson / fromJson khớp định dạng API', () {
      final e = LearningEvent(
        type: LearningEventType.pronunciationScored,
        occurredAt: DateTime.utc(2026, 11, 20, 12),
        xp: 5,
        durationSec: 40,
        score: 92,
        refId: '你好',
      );
      final j = e.toJson();
      expect(j['type'], 'pronunciation_scored');
      expect(j['occurred_at'], '2026-11-20T12:00:00.000Z');
      expect(j.containsKey('data'), isFalse);
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(e.id), isTrue);
      final back = LearningEvent.fromJson(j);
      expect(back.id, e.id);
      expect(back.type, e.type);
      expect(back.score, 92);
    });

    test('ProgressSummary tính streak, XP, phút học', () {
      final now = DateTime(2026, 11, 21, 20);
      LearningEvent at(int daysAgo, {int xp = 1, int sec = 120}) => LearningEvent(
        type: LearningEventType.srsReview,
        occurredAt: now.subtract(Duration(days: daysAgo)),
        xp: xp,
        durationSec: sec,
      );
      final s = ProgressSummary.from([at(0), at(0), at(1), at(4), at(5), at(6), at(7)], now: now);
      expect(s.currentStreak, 2);
      expect(s.longestStreak, 4);
      expect(s.xpTotal, 7);
      expect(s.minutesOn(now), 4);

      final yesterdayOnly = ProgressSummary.from([at(1)], now: now);
      expect(yesterdayOnly.currentStreak, 1, reason: 'chưa học hôm nay vẫn giữ streak tới hết ngày');
      expect(ProgressSummary.from([at(2)], now: now).currentStreak, 0);
    });

    test('generateDemoEvents tạo 30 ngày có streak', () async {
      final lessons = await AssetLessonRepository().lessons();
      final now = DateTime(2026, 11, 21, 21);
      final events = generateDemoEvents(lessons, now: now);
      final s = ProgressSummary.from(events, now: now);
      expect(events.length, greaterThan(100));
      expect(s.currentStreak, greaterThanOrEqualTo(5));
      expect(s.minutesByDay.length, lessThan(30), reason: 'có ngày nghỉ cho heatmap');
      expect(events.every((e) => !e.occurredAt.isAfter(now)), isTrue);
      expect(s.countByType.keys, containsAll(LearningEventType.values.where((t) =>
          t != LearningEventType.quizCompleted && t != LearningEventType.placementCompleted && t != LearningEventType.studySession)));
    });
  });

  group('Bản giả', () {
    test('FakePronunciationScorer: ổn định, đủ âm tiết, JSON khứ hồi', () async {
      final scorer = FakePronunciationScorer();
      final a = await scorer.assess(referenceHanzi: '我是学生。', referencePinyin: 'wǒ shì xué sheng');
      final b = await scorer.assess(referenceHanzi: '我是学生。', referencePinyin: 'wǒ shì xué sheng');
      expect(a.syllables.length, 4);
      expect(a.toJson(), b.toJson());
      expect(a.syllables[1].expected.initial, 'sh');
      final back = PronunciationResult.fromJson(jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
      expect(back.toJson(), a.toJson());
    });

    test('splitPinyin tách thanh mẫu / vận mẫu / thanh điệu', () {
      expect(splitPinyin('hǎo').toString(), 'hao3');
      expect(splitPinyin('zhōng').initial, 'zh');
      expect(splitPinyin('zhōng').finalPart, 'ong');
      expect(splitPinyin('lǜ').tone, 4);
      expect(splitPinyin('ma').tone, 5);
      expect(splitPinyin('ài').initial, '');
    });

    test('FakePinyinService tra theo từ vựng mẫu, ưu tiên từ dài', () async {
      final pinyin = FakePinyinService(AssetLessonRepository());
      expect(await pinyin.toPinyin('你好'), 'nǐ hǎo');
      expect(await pinyin.toPinyin('我是你妈妈！'), 'wǒ shì nǐ māma');
      expect(await pinyin.toPinyin('龙'), '?');
    });

    test('FakeHanziRepository có nét theo thứ tự', () async {
      final repo = FakeHanziRepository();
      expect(await repo.available(), contains('口'));
      final kou = await repo.strokes('口');
      expect(kou!.strokeCount, 3);
      expect(kou.strokes.first, startsWith('M '));
      expect(kou.strokes.first, endsWith(' Z'));
      expect(await repo.strokes('龙'), isNull);
      final round = HanziStrokes.fromJson(kou.toJson());
      expect(round.medians.first.first, kou.medians.first.first);
    });

    test('FakeSrsService đếm thẻ đến hạn và thêm từ mới', () async {
      final repo = AssetLessonRepository();
      final srs = FakeSrsService(repo);
      final before = await srs.dueCount();
      expect(before, greaterThan(0));
      final lesson3 = (await repo.lessons())[2];
      await srs.addWords(lesson3.words);
      expect(await srs.dueCount(), greaterThan(before));
    });
  });

  group('Outbox + ProgressService', () {
    late List<http.Request> sent;
    late SecureStorageService storage;
    late ApiClient api;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      sent = [];
      storage = SecureStorageService(const FlutterSecureStorage());
      api = ApiClient(
        baseUrl: 'http://x/api',
        storage: storage,
        client: MockClient((req) async {
          sent.add(req);
          final n = (jsonDecode(req.body)['events'] as List).length;
          return http.Response(
            jsonEncode({'accepted': n, 'duplicates': 0, 'xp_total': n, 'current_streak': 1, 'longest_streak': 1}),
            200,
          );
        }),
      );
    });

    test('chưa đăng nhập thì giữ lại, đăng nhập xong flush gửi lên /events', () async {
      final outbox = MemoryOutbox(api);
      final progress = LocalProgressService(outbox, api);
      await progress.record(LearningEvent(type: LearningEventType.srsReview, xp: 1));
      await outbox.flush();
      expect(sent, isEmpty);
      expect(await outbox.pendingCount(), 1);
      expect(progress.events.length, 1);

      await storage.saveToken('token');
      await outbox.flush();
      expect(sent.single.url.path, '/api/events');
      expect(sent.single.headers['Authorization'], 'Bearer token');
      expect(await outbox.pendingCount(), 0);
    });

    test('dữ liệu giả từ addAll không gửi lên server', () async {
      await storage.saveToken('token');
      final outbox = MemoryOutbox(api);
      final progress = LocalProgressService(outbox, api);
      await progress.addAll([LearningEvent(type: LearningEventType.studySession)]);
      await outbox.flush();
      expect(sent, isEmpty);
      expect(progress.events.length, 1);
    });
  });

  test('mọi provider hợp đồng mặc định khởi tạo được', () {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    for (final c in contractEntries) {
      expect(container.read(c.provider), isNotNull, reason: c.name);
    }
  });
}
