import 'package:english_pronunciation_app/data/app_database.dart';
import 'package:english_pronunciation_app/data/export.dart';
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

  Future<int> speak(String lesson, String expected, String heard, {double confidence = 0.8}) async {
    final sid = await db.startSession(user.id, lesson);
    await db.saveAttempt(user.id, sid, scorePronunciation(expected, heard, confidence: confidence));
    return sid;
  }

  test('người mới: chưa có thống kê', () async {
    final s = await db.stats(user.id);
    expect((s.streak, s.attempts, s.practicedToday), (0, 0, false));
    expect(s.weakSounds, isEmpty);
    expect(s.rate, isNull);
  });

  test('một lượt nói hôm nay: streak 1 và practicedToday', () async {
    await speak('th', 'think', 'think');
    final s = await db.stats(user.id);
    expect((s.streak, s.practicedToday, s.attempts), (1, true, 1));
  });

  test('phiên không có lượt nói không tính vào streak, nhưng thời gian vẫn cộng', () async {
    final sid = await db.startSession(user.id, 'th');
    await db.endSession(sid, 120);
    final s = await db.stats(user.id);
    expect((s.streak, s.practicedToday), (0, false));
    expect(s.secondsToday, 120);
  });

  test('điểm cao nhất theo từng mục và theo bài', () async {
    await speak('th', 'think', 'sink'); // sai
    await speak('th', 'think', 'think'); // đúng
    await speak('th', 'three', 'tree');
    final l = (await db.stats(user.id)).lessons['th']!;
    expect(l.attempts, 3);
    expect(l.itemBest['think'], 98); // lượt đúng: 100×0.9 + 0.8×10
    expect(l.itemBest['think']!, greaterThan(l.itemBest['three']!));
  });

  test('âm hay sai: tính theo tỉ lệ, cần gặp tối thiểu 3 lần', () async {
    for (var i = 0; i < 3; i++) {
      await speak('th', 'think', 'sink');
    }
    final s = await db.stats(user.id);
    expect(s.weakSounds.map((w) => w.phoneme), ['TH']);
    expect(s.weakSounds.single.rate, 1.0);
  });

  test('chỉ xét weakWindow lượt gần nhất', () async {
    for (var i = 0; i < 3; i++) {
      await speak('th', 'think', 'sink'); // lỗi cũ
    }
    for (var i = 0; i < weakWindow; i++) {
      await speak('rl', 'road', 'road'); // đẩy lỗi cũ ra khỏi cửa sổ
    }
    expect((await db.stats(user.id)).weakSounds, isEmpty);
  });

  test('chấm lại từ dữ liệu đã lưu ra đúng kết quả đã lưu', () async {
    final r = scorePronunciation('I think three is enough', 'I sink tree is enough', confidence: 0.7);
    final sid = await db.startSession(user.id, 'th');
    await db.saveAttempt(user.id, sid, r);
    final row = (await db.db.query('attempts')).single;
    final again = scorePronunciation(row['expected_text'] as String, row['recognized_text'] as String,
        confidence: (row['confidence'] as num).toDouble());
    expect(again.score, row['score']);
    expect(again.errors.length, r.errors.length);
    expect(await db.db.query('phoneme_errors'), hasLength(r.errors.length));
  });

  test('xóa người học xóa luôn lịch sử (ON DELETE CASCADE)', () async {
    await speak('th', 'think', 'sink');
    await db.deleteUser(user.id);
    for (final t in ['practice_sessions', 'attempts', 'phoneme_errors']) {
      expect(await db.db.query(t), isEmpty, reason: t);
    }
  });

  test('dữ liệu hai người học tách biệt', () async {
    final other = await db.createUser('Khac');
    await speak('th', 'think', 'think');
    expect((await db.stats(other.id)).attempts, 0);
  });

  test('xu hướng điểm: đủ $trendDays ngày, ngày không luyện là null, ngày luyện có trung bình', () async {
    await speak('th', 'think', 'think', confidence: 0); // 100
    await speak('th', 'think', 'think', confidence: 0); // 100
    final t = (await db.stats(user.id)).scoreTrend;
    expect(t, hasLength(trendDays));
    expect(t.last.date, dayKey(DateTime.now()));
    expect(t.last.avg, 100);
    expect(t.take(trendDays - 1).every((d) => d.avg == null), isTrue);
  });

  test('nhãn thứ trong tuần', () {
    expect(weekdayLabel('2026-11-23'), 'T2'); // thứ Hai
    expect(weekdayLabel('2026-11-29'), 'CN'); // Chủ nhật
  });

  test('allAttempts: cũ nhất trước, chỉ của người học đó, xuất CSV đủ dòng', () async {
    final other = await db.createUser('Khac');
    await speak('th', 'think', 'sink');
    await speak('rl', 'right', 'right');
    final sid = await db.startSession(other.id, 'th');
    await db.saveAttempt(other.id, sid, scorePronunciation('three', 'three'));
    final rows = await db.allAttempts(user.id);
    expect(rows.map((r) => r['expected_text']), ['think', 'right']);
    expect(attemptsToCsv(rows).trim().split('\n'), hasLength(3)); // tiêu đề + 2 lượt
  });

  test('dữ liệu demo: streak hiện tại 6, kỷ lục 8, đủ lượt để có rate', () async {
    await db.deleteUser(user.id); // seed chỉ chạy khi CSDL chưa có người học
    await db.seedDemoIfEmpty();
    final demo = (await db.users()).single;
    final s = await db.stats(demo.id);
    expect((s.streak, s.bestStreak), (6, 8));
    expect(s.rate, isNotNull);
  });
}
