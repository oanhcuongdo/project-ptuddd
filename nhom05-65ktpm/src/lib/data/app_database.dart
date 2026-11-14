import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../scoring/pronunciation_scorer.dart';

class User {
  final int id;
  final String name;
  final int dailyGoalMinutes;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  const User(this.id, this.name, this.dailyGoalMinutes, this.reminderEnabled,
      this.reminderHour, this.reminderMinute);

  factory User.fromRow(Map<String, Object?> r) => User(
        r['id'] as int,
        r['name'] as String,
        r['daily_goal_minutes'] as int,
        r['reminder_enabled'] == 1,
        r['reminder_hour'] as int,
        r['reminder_minute'] as int,
      );
}

class DayStat {
  final String date;
  final int seconds;
  const DayStat(this.date, this.seconds);
}

class Stats {
  final int streak;
  final int bestStreak;
  final int secondsToday;
  final int totalSeconds;
  final int attempts;
  final double avgScore;
  final List<DayStat> last7Days;
  final Map<String, int> topErrors; // expected phoneme -> count
  final List<Map<String, Object?>> recentAttempts;

  const Stats(this.streak, this.bestStreak, this.secondsToday, this.totalSeconds,
      this.attempts, this.avgScore, this.last7Days, this.topErrors,
      this.recentAttempts);
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Current streak counts back from today, or from yesterday if the user has
/// not practiced yet today (the streak is still alive until midnight).
({int current, int best}) computeStreak(Set<String> days, DateTime today) {
  var d = DateTime(today.year, today.month, today.day);
  if (!days.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
  var current = 0;
  while (days.contains(dayKey(d))) {
    current++;
    d = DateTime(d.year, d.month, d.day - 1);
  }

  var best = 0, run = 0;
  DateTime? prev;
  for (final k in days.toList()..sort()) {
    final day = DateTime.parse(k);
    run = prev != null && DateTime(prev.year, prev.month, prev.day + 1) == day
        ? run + 1
        : 1;
    if (run > best) best = run;
    prev = day;
  }
  return (current: current, best: best);
}

class AppDatabase {
  final Database db;
  AppDatabase._(this.db);

  static Future<AppDatabase> open() async {
    if (kIsWeb) databaseFactory = databaseFactoryFfiWebNoWebWorker; // web demo only
    final db = await openDatabase(
      kIsWeb ? 'english_app.db' : join(await getDatabasesPath(), 'english_app.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            daily_goal_minutes INTEGER NOT NULL DEFAULT 10,
            reminder_enabled INTEGER NOT NULL DEFAULT 1,
            reminder_hour INTEGER NOT NULL DEFAULT 20,
            reminder_minute INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL)''');
        await db.execute('''
          CREATE TABLE practice_sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            lesson_id TEXT NOT NULL,
            day TEXT NOT NULL,
            started_at TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''
          CREATE TABLE attempts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL REFERENCES practice_sessions(id) ON DELETE CASCADE,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            expected_text TEXT NOT NULL,
            recognized_text TEXT NOT NULL,
            score INTEGER NOT NULL,
            confidence REAL NOT NULL,
            created_at TEXT NOT NULL)''');
        await db.execute('''
          CREATE TABLE phoneme_errors(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attempt_id INTEGER NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
            word TEXT NOT NULL,
            expected_phoneme TEXT,
            actual_phoneme TEXT,
            error_type TEXT NOT NULL)''');
        await db.execute('CREATE INDEX idx_sessions_user_day ON practice_sessions(user_id, day)');
        await db.execute('CREATE INDEX idx_attempts_user ON attempts(user_id)');
      },
    );
    return AppDatabase._(db);
  }

  Future<List<User>> users() async =>
      (await db.query('users', orderBy: 'name')).map(User.fromRow).toList();

  Future<User> createUser(String name) async {
    final id = await db.insert('users', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
    return User.fromRow((await db.query('users', where: 'id = ?', whereArgs: [id])).single);
  }

  Future<void> deleteUser(int id) => db.delete('users', where: 'id = ?', whereArgs: [id]);

  Future<User> updateSettings(User u,
      {int? goal, bool? reminder, int? hour, int? minute}) async {
    await db.update(
      'users',
      {
        'daily_goal_minutes': goal ?? u.dailyGoalMinutes,
        'reminder_enabled': (reminder ?? u.reminderEnabled) ? 1 : 0,
        'reminder_hour': hour ?? u.reminderHour,
        'reminder_minute': minute ?? u.reminderMinute,
      },
      where: 'id = ?',
      whereArgs: [u.id],
    );
    return User.fromRow((await db.query('users', where: 'id = ?', whereArgs: [u.id])).single);
  }

  Future<int> startSession(int userId, String lessonId) {
    final now = DateTime.now();
    return db.insert('practice_sessions', {
      'user_id': userId,
      'lesson_id': lessonId,
      'day': dayKey(now),
      'started_at': now.toIso8601String(),
    });
  }

  Future<void> endSession(int sessionId, int seconds) async {
    if (seconds <= 0) return;
    await db.update('practice_sessions', {'duration_seconds': seconds},
        where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> saveAttempt(int userId, int sessionId, PronunciationResult r,
          {DateTime? at}) =>
      db.transaction((txn) async {
        final id = await txn.insert('attempts', {
          'session_id': sessionId,
          'user_id': userId,
          'expected_text': r.expectedText,
          'recognized_text': r.recognizedText,
          'score': r.score,
          'confidence': r.confidence,
          'created_at': (at ?? DateTime.now()).toIso8601String(),
        });
        for (final e in r.errors) {
          await txn.insert('phoneme_errors', {
            'attempt_id': id,
            'word': e.word,
            'expected_phoneme': e.expected,
            'actual_phoneme': e.actual,
            'error_type': e.type.name,
          });
        }
      });

  /// Fills an empty database with one demo learner: a 6-day streak ending
  /// yesterday (practicing today makes it 7), an older 8-day best streak, and
  /// attempts scored by the real scorer so errors and tips are consistent.
  Future<void> seedDemoIfEmpty() async {
    if ((await users()).isNotEmpty) return;
    final user = await createUser('Minh (demo)');
    const pairs = [
      ('th', 'I think three is enough', 'I sink tree is enough'),
      ('th', 'think', 'sink'),
      ('th', 'three', 'tree'),
      ('th', 'Thank you for this', 'Thank you for this'),
      ('vw', 'very', 'berry'),
      ('vw', 'We visit very warm villages', 'We visit very warm villages'),
      ('rl', 'right', 'light'),
      ('rl', 'The red light is right there', 'The red light is right there'),
      ('ii', 'sheep', 'ship'),
      ('ii', 'Please sit in this seat', 'Please sit in this seat'),
      ('final', 'cats', 'cat'),
      ('final', 'She likes cats and dogs', 'She like cat and dog'),
      ('ssh', 'She sells sea shells', 'see sells sea shells'),
      ('daily', 'Nice to meet you', 'Nice to meet you'),
    ];
    final today = DateTime.now();
    // Days ago with practice: 1..6 is the current streak, 10..17 the best one.
    final days = [for (var i = 1; i <= 6; i++) i, for (var i = 10; i <= 17; i++) i];
    var k = 0;
    for (final ago in days) {
      final start = DateTime(today.year, today.month, today.day - ago, 20, 5);
      final p = pairs[k % pairs.length];
      final sid = await db.insert('practice_sessions', {
        'user_id': user.id,
        'lesson_id': p.$1,
        'day': dayKey(start),
        'started_at': start.toIso8601String(),
        'duration_seconds': 360 + (ago * 97) % 420, // 6–13 min
      });
      for (var j = 0; j < 3; j++, k++) {
        final q = pairs[k % pairs.length];
        await saveAttempt(user.id, sid, scorePronunciation(q.$2, q.$3, confidence: 0.85),
            at: start.add(Duration(minutes: j * 2)));
      }
    }
  }

  Future<Stats> stats(int userId) async {
    final now = DateTime.now();
    // A day counts toward the streak only if the user made at least one attempt.
    final dayRows = await db.rawQuery('''
      SELECT DISTINCT s.day FROM practice_sessions s
      JOIN attempts a ON a.session_id = s.id
      WHERE s.user_id = ?''', [userId]);
    final streak = computeStreak(dayRows.map((r) => r['day'] as String).toSet(), now);

    final from = dayKey(now.subtract(const Duration(days: 6)));
    final perDay = {
      for (final r in await db.rawQuery('''
        SELECT day, SUM(duration_seconds) AS secs FROM practice_sessions
        WHERE user_id = ? AND day >= ? GROUP BY day''', [userId, from]))
        r['day'] as String: (r['secs'] as int?) ?? 0,
    };
    final last7 = [
      for (var i = 6; i >= 0; i--)
        DayStat(dayKey(now.subtract(Duration(days: i))),
            perDay[dayKey(now.subtract(Duration(days: i)))] ?? 0),
    ];

    final total = (await db.rawQuery(
            'SELECT SUM(duration_seconds) AS t FROM practice_sessions WHERE user_id = ?',
            [userId]))
        .single['t'] as int?;
    final agg = (await db.rawQuery(
            'SELECT COUNT(*) AS c, AVG(score) AS avg FROM attempts WHERE user_id = ?',
            [userId]))
        .single;
    final errs = await db.rawQuery('''
      SELECT e.expected_phoneme AS p, COUNT(*) AS c FROM phoneme_errors e
      JOIN attempts a ON a.id = e.attempt_id
      WHERE a.user_id = ? AND e.expected_phoneme IS NOT NULL
      GROUP BY e.expected_phoneme ORDER BY c DESC LIMIT 5''', [userId]);
    final recent = await db.query('attempts',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'id DESC', limit: 10);

    return Stats(
      streak.current,
      streak.best,
      perDay[dayKey(now)] ?? 0,
      total ?? 0,
      agg['c'] as int,
      (agg['avg'] as num?)?.toDouble() ?? 0,
      last7,
      {for (final r in errs) r['p'] as String: r['c'] as int},
      recent,
    );
  }
}
