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
}
