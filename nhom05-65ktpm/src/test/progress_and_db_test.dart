import 'dart:io';

import 'package:english_pronunciation_app/data/app_database.dart';
import 'package:english_pronunciation_app/scoring/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await AppDatabase.open(path: inMemoryDatabasePath);
  });

  tearDown(() async => database.close());

  test('fresh schema stores score source and nullable audio path', () async {
    final user = await database.createUser('Learner');
    final session = await database.startSession(user.id, 'th');
    final result = scorePronunciation('think', 'sink');

    await database.saveAttempt(
      user.id,
      session,
      result,
      scoringSource: 'ai',
      audioPath: '/recordings/think.wav',
    );

    final row = (await database.db.query('attempts')).single;
    expect(row['scoring_source'], 'ai');
    expect(row['audio_path'], '/recordings/think.wav');
  });

  test('learner profile name and avatar color can be updated', () async {
    final user = await database.createUser('Learner');
    final updated = await database.updateProfile(
      user,
      name: 'Updated learner',
      avatarColor: 0xFF006A60,
    );

    expect(updated.name, 'Updated learner');
    expect(updated.avatarColor, 0xFF006A60);
  });

  test('v1 database upgrades without losing attempt rows', () async {
    await database.close();
    final directory = await Directory.systemTemp.createTemp(
      'speak_up_migration_',
    );
    final path = '${directory.path}${Platform.pathSeparator}legacy.db';
    var legacy = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
          daily_goal_minutes INTEGER NOT NULL DEFAULT 10,
          reminder_enabled INTEGER NOT NULL DEFAULT 1,
          reminder_hour INTEGER NOT NULL DEFAULT 20,
          reminder_minute INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE practice_sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL REFERENCES users(id), lesson_id TEXT NOT NULL,
          day TEXT NOT NULL, started_at TEXT NOT NULL,
          duration_seconds INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''CREATE TABLE attempts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL REFERENCES practice_sessions(id),
          user_id INTEGER NOT NULL REFERENCES users(id), expected_text TEXT NOT NULL,
          recognized_text TEXT NOT NULL, score INTEGER NOT NULL,
          confidence REAL NOT NULL, created_at TEXT NOT NULL)''');
        await db.execute(
          '''CREATE TABLE phoneme_errors(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          attempt_id INTEGER NOT NULL REFERENCES attempts(id), word TEXT NOT NULL,
          expected_phoneme TEXT, actual_phoneme TEXT, error_type TEXT NOT NULL)''',
        );
        await db.insert('users', {
          'name': 'Legacy',
          'created_at': '2026-01-01T10:00:00',
        });
        await db.insert('practice_sessions', {
          'user_id': 1,
          'lesson_id': 'th',
          'day': '2026-01-01',
          'started_at': '2026-01-01T10:00:00',
        });
        await db.insert('attempts', {
          'session_id': 1,
          'user_id': 1,
          'expected_text': 'think',
          'recognized_text': 'sink',
          'score': 80,
          'confidence': 0.8,
          'created_at': '2026-01-01T10:00:00',
        });
      },
    );
    await legacy.close();

    database = await AppDatabase.open(path: path);
    try {
      final row = (await database.db.query('attempts')).single;
      expect(row['expected_text'], 'think');
      expect(row['scoring_source'], 'offline');
      expect(row['audio_path'], isNull);
      expect((await database.users()).single.avatarColor, 0xFF6750A4);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
      database = await AppDatabase.open(path: inMemoryDatabasePath);
    }
  });

  test('daily score aggregate is filtered by learner and date range', () async {
    final first = await database.createUser('First');
    final second = await database.createUser('Second');
    final session1 = await database.startSession(first.id, 'th');
    final session2 = await database.startSession(second.id, 'th');
    final day = DateTime.now();
    final result1 = _result(80);
    final result2 = _result(100);
    await database.saveAttempt(first.id, session1, result1, at: day);
    await database.saveAttempt(
      first.id,
      session1,
      result2,
      at: day.add(const Duration(minutes: 2)),
    );
    await database.saveAttempt(second.id, session2, _result(20), at: day);

    final scores = await database.dailyAverageScores(
      first.id,
      days: 7,
      until: day,
    );
    expect(scores, hasLength(1));
    expect(scores.single.averageScore, 90);
    expect(scores.single.attemptCount, 2);
  });

  test('same-day sessions count as one practice day in user streak', () async {
    final user = await database.createUser('Streak');
    final today = DateTime(2026, 3, 1);
    for (final day in [
      DateTime(2026, 2, 27),
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 1),
    ]) {
      final session = await database.startSession(user.id, 'th', at: day);
      await database.saveAttempt(
        user.id,
        session,
        _result(70),
        at: DateTime(day.year, day.month, day.day, 12),
      );
    }
    final session2 = await database.startSession(
      user.id,
      'vw',
      at: DateTime(2026, 2, 28, 18),
    );
    await database.saveAttempt(
      user.id,
      session2,
      _result(80),
      at: DateTime(2026, 2, 28, 18),
    );

    final streak = await database.streakForUser(user.id, today: today);
    expect(streak.current, 3);
    expect(streak.best, 3);
  });

  test('streak resets after a missing day and keeps all-time best', () async {
    final user = await database.createUser('Broken streak');
    for (final day in [1, 2, 3, 4, 8]) {
      final session = await database.startSession(
        user.id,
        'th',
        at: DateTime(2026, 2, day, 12),
      );
      await database.saveAttempt(
        user.id,
        session,
        _result(70),
        at: DateTime(2026, 2, day, 12),
      );
    }
    final streak = await database.streakForUser(
      user.id,
      today: DateTime(2026, 2, 8),
    );
    expect(streak.current, 1);
    expect(streak.best, 4);
  });

  test('top phoneme errors are grouped and isolated per profile', () async {
    final first = await database.createUser('First');
    final second = await database.createUser('Second');
    final firstSession = await database.startSession(first.id, 'th');
    final secondSession = await database.startSession(second.id, 'th');
    await database.saveAttempt(
      first.id,
      firstSession,
      _result(60, phoneme: 'TH', repeats: 3),
    );
    await database.saveAttempt(
      first.id,
      firstSession,
      _result(60, phoneme: 'R', repeats: 2),
    );
    await database.saveAttempt(
      second.id,
      secondSession,
      _result(60, phoneme: 'V', repeats: 5),
    );

    final top = await database.topMispronouncedPhonemes(first.id);
    expect(top.map((entry) => (entry.phoneme, entry.count)), [
      ('TH', 3),
      ('R', 2),
    ]);
  });
}

PronunciationResult _result(int score, {String? phoneme, int repeats = 0}) {
  final errors = [
    for (var i = 0; i < repeats; i++)
      PhonemeError(0, 'think', phoneme, 'S', ErrorType.substitution, false),
  ];
  return PronunciationResult('think', 'sink', score, 0.8, const [], errors);
}
