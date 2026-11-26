import 'package:english_pronunciation_app/data/app_database.dart';
import 'package:english_pronunciation_app/scoring/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late User user;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath);
    user = await db.createUser('Test');
  });

  tearDown(() => db.db.close());

  test('người mới: streak 0', () async {
    final s = await db.stats(user.id);
    expect((s.streak, s.bestStreak), (0, 0));
  });

  test('một lượt nói hôm nay: streak 1', () async {
    final sid = await db.startSession(user.id, 'th');
    await db.saveAttempt(user.id, sid, scorePronunciation('think', 'think'));
    expect((await db.stats(user.id)).streak, 1);
  });

  test('phiên không có lượt nói không tính vào streak', () async {
    await db.startSession(user.id, 'th');
    expect((await db.stats(user.id)).streak, 0);
  });

  test('phiên bắt đầu trước nửa đêm nhưng nói sau nửa đêm: ngày tính theo lượt nói', () async {
    final now = DateTime.now();
    DateTime at(int daysAgo, int h, int m) =>
        DateTime(now.year, now.month, now.day - daysAgo, h, m);
    Future<int> session(DateTime start) => db.db.insert('practice_sessions', {
          'user_id': user.id,
          'lesson_id': 'th',
          'day': dayKey(start),
          'started_at': start.toIso8601String(),
        });

    // Hôm kia: một phiên bình thường.
    final s1 = await session(at(2, 20, 0));
    await db.saveAttempt(user.id, s1, scorePronunciation('think', 'think'), at: at(2, 20, 5));
    // Phiên bắt đầu 23:58 hôm qua nhưng lượt nói xảy ra lúc 00:03 hôm nay.
    final s2 = await session(at(1, 23, 58));
    await db.saveAttempt(user.id, s2, scorePronunciation('think', 'think'), at: at(0, 0, 3));

    // Ngày có lượt nói: hôm kia và hôm nay (hôm qua không nói) → mỗi chuỗi dài 1.
    final s = await db.stats(user.id);
    expect((s.streak, s.bestStreak), (1, 1));
  });
}
