import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';

/// Quản lý CSDL SQLite cục bộ theo triết lý Offline-First cho BuddyTalk.
/// Lưu bộ đệm nhiệm vụ kỷ luật (Streak/Heatmap), sổ tay từ vựng,
/// tiến độ chủ đề và lịch sử buổi luyện tập ngay trên thiết bị Android.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseTables.localDbName);

    return openDatabase(
      path,
      version: DatabaseTables.localDbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng nhật ký kỷ luật hàng ngày (Streak & Ma trận Heatmap)
    await db.execute('''
      CREATE TABLE ${DatabaseTables.localQuestLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        log_date TEXT NOT NULL,
        goal_minutes INTEGER NOT NULL DEFAULT 15,
        completed_minutes INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        emotion_note TEXT DEFAULT '',
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, log_date)
      )
    ''');

    // 2. Bảng Sổ tay từ vựng cá nhân (Vocabulary Notebook)
    await db.execute('''
      CREATE TABLE ${DatabaseTables.localVocabNotebook} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        word TEXT NOT NULL,
        translated_meaning TEXT NOT NULL,
        source_lang TEXT NOT NULL DEFAULT 'en',
        target_lang TEXT NOT NULL DEFAULT 'vi',
        example_sentence TEXT DEFAULT '',
        is_mastered INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Bảng lịch sử buổi luyện tập (Practice Sessions - Kiên)
    await db.execute('''
      CREATE TABLE ${DatabaseTables.localPracticeSessions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        buddy_id TEXT,
        topic_id TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 15,
        notes TEXT DEFAULT '',
        rating INTEGER,
        completed_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 4. Bảng theo dõi trạng thái hoàn thành chủ đề hội thoại (Đạo)
    await db.execute('''
      CREATE TABLE ${DatabaseTables.localTopicProgress} (
        topic_id TEXT PRIMARY KEY,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT
      )
    ''');
  }

  // ===========================================================================
  // CÁC HÀM CRUD CƠ BẢN CHO PHÂN HỆ KỶ LUẬT (STREAK & HEATMAP)
  // ===========================================================================

  /// Lưu hoặc cập nhật check-in kỷ luật cho một ngày (logDate dạng 'YYYY-MM-DD')
  Future<int> upsertQuestLog({
    required String userId,
    required String logDate,
    required int goalMinutes,
    required int completedMinutes,
    required bool isCompleted,
    String emotionNote = '',
  }) async {
    final db = await database;
    return db.insert(
      DatabaseTables.localQuestLogs,
      {
        'user_id': userId,
        'log_date': logDate,
        'goal_minutes': goalMinutes,
        'completed_minutes': completedMinutes,
        'is_completed': isCompleted ? 1 : 0,
        'emotion_note': emotionNote,
        'is_synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách check-in theo tháng (yearMonth dạng 'YYYY-MM') để vẽ Heatmap
  Future<List<Map<String, dynamic>>> getQuestLogsByMonth({
    required String userId,
    required String yearMonth,
  }) async {
    final db = await database;
    return db.query(
      DatabaseTables.localQuestLogs,
      where: 'user_id = ? AND log_date LIKE ?',
      whereArgs: [userId, '$yearMonth%'],
      orderBy: 'log_date ASC',
    );
  }

  /// Tính chuỗi ngày kỷ luật liên tiếp (Current Streak)
  Future<int> calculateCurrentStreak(String userId) async {
    final db = await database;
    final rows = await db.query(
      DatabaseTables.localQuestLogs,
      columns: ['log_date'],
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [userId],
      orderBy: 'log_date DESC',
    );

    if (rows.isEmpty) return 0;

    final completedDates = rows
        .map((r) => r['log_date'] as String)
        .toSet();

    int streak = 0;
    DateTime cursor = DateTime.now();
    String formatDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // Nếu hôm nay chưa check-in, bắt đầu đếm từ hôm qua để không mất chuỗi trong ngày
    if (!completedDates.contains(formatDate(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (completedDates.contains(formatDate(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ===========================================================================
  // CÁC HÀM CRUD CƠ BẢN CHO SỔ TAY TỪ VỰNG (VOCABULARY NOTEBOOK)
  // ===========================================================================

  Future<int> insertVocab({
    required String userId,
    required String word,
    required String translatedMeaning,
    String sourceLang = 'en',
    String targetLang = 'vi',
    String exampleSentence = '',
  }) async {
    final db = await database;
    return db.insert(DatabaseTables.localVocabNotebook, {
      'user_id': userId,
      'word': word,
      'translated_meaning': translatedMeaning,
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'example_sentence': exampleSentence,
      'is_mastered': 0,
      'is_synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllVocab(String userId) async {
    final db = await database;
    return db.query(
      DatabaseTables.localVocabNotebook,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteVocab(int id) async {
    final db = await database;
    return db.delete(
      DatabaseTables.localVocabNotebook,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // ĐÁNH DẤU HOÀN THÀNH CHỦ ĐỀ HỘI THOẠI (TOPICS)
  // ===========================================================================

  Future<void> markTopicCompleted(String topicId, bool isCompleted) async {
    final db = await database;
    await db.insert(
      DatabaseTables.localTopicProgress,
      {
        'topic_id': topicId,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<String>> getCompletedTopicIds() async {
    final db = await database;
    final rows = await db.query(
      DatabaseTables.localTopicProgress,
      columns: ['topic_id'],
      where: 'is_completed = 1',
    );
    return rows.map((r) => r['topic_id'] as String).toSet();
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
