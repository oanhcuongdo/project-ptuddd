import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/sleep_goal_model.dart';
import '../models/sleep_record_model.dart';
import '../models/nap_record_model.dart';
import '../models/reminder_model.dart';
import '../models/ai_message_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static String? _customPath;

  /// Phiên bản CSDL hiện tại (v2 hỗ trợ cột is_offline)
  static int get databaseVersion => AppConstants.dbVersion;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (_database != null && _database!.isOpen) return _database;
    try {
      _database = await _initDB(_customPath ?? AppConstants.dbName);
      return _database;
    } catch (e) {
      debugPrint('[DatabaseHelper] SQLite fallback: $e');
      return null;
    }
  }

  @visibleForTesting
  Future<Database> initCustomDatabase({String? path}) async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
    _customPath = path ?? inMemoryDatabasePath;
    _database = await _initDB(_customPath!);
    return _database!;
  }

  @visibleForTesting
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _customPath = null;
  }

  Future<Database> _initDB(String filePath) async {
    final String path;
    if (_customPath != null || filePath == inMemoryDatabasePath) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: onUpgrade,
    );
  }

  @visibleForTesting
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${AppConstants.tableAIConversations} ADD COLUMN is_offline INTEGER NOT NULL DEFAULT 0;');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        student_id TEXT NOT NULL,
        class_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. SleepGoals table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSleepGoals} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bedtime_hour INTEGER NOT NULL,
        bedtime_minute INTEGER NOT NULL,
        wake_hour INTEGER NOT NULL,
        wake_minute INTEGER NOT NULL,
        target_duration_hours REAL NOT NULL,
        active_days TEXT NOT NULL,
        is_reminder_enabled INTEGER NOT NULL
      )
    ''');

    // 3. SleepRecords table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSleepRecords} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sleep_time TEXT NOT NULL,
        wake_time TEXT NOT NULL,
        duration_hours REAL NOT NULL,
        wake_up_count INTEGER NOT NULL,
        feeling_rating INTEGER NOT NULL,
        note TEXT NOT NULL,
        is_goal_met INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. NapRecords table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNapRecords} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Reminders table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableReminders} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        type TEXT NOT NULL,
        is_enabled INTEGER NOT NULL
      )
    ''');

    // 6. AIConversations table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAIConversations} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        is_offline INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL
      )
    ''');

    // Seed default initial data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed default user
    await db.insert(
      AppConstants.tableUsers,
      UserModel(
        name: 'Mã Khánh Linh',
        email: 'mkl.deeptry@gmail.com',
        studentId: '2351170602',
        className: '65KTPM',
      ).toMap(),
    );

    // Seed default goal (23:00 -> 07:00, 8h)
    await db.insert(
      AppConstants.tableSleepGoals,
      SleepGoalModel(
        bedtimeHour: AppConstants.defaultBedtimeHour,
        bedtimeMinute: AppConstants.defaultBedtimeMinute,
        wakeHour: AppConstants.defaultWakeHour,
        wakeMinute: AppConstants.defaultWakeMinute,
        targetDurationHours: AppConstants.defaultTargetDurationHours,
      ).toMap(),
    );

    // Seed default reminders
    await db.insert(
      AppConstants.tableReminders,
      ReminderModel(title: 'Chuẩn bị đi ngủ (tắt điện thoại)', hour: 22, minute: 30, type: 'prepare_sleep').toMap(),
    );
    await db.insert(
      AppConstants.tableReminders,
      ReminderModel(title: 'Đến giờ ngủ mục tiêu', hour: 23, minute: 0, type: 'bedtime').toMap(),
    );
    await db.insert(
      AppConstants.tableReminders,
      ReminderModel(title: 'Thức dậy đón ngày mới', hour: 7, minute: 0, type: 'wakeup').toMap(),
    );

    // Seed some mock sleep records for recent 7 days so charts render nicely
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final sleepTime = DateTime(day.year, day.month, day.day - 1, 23, 15);
      final wakeTime = DateTime(day.year, day.month, day.day, 7, 0);
      final duration = wakeTime.difference(sleepTime).inMinutes / 60.0;

      await db.insert(
        AppConstants.tableSleepRecords,
        SleepRecordModel(
          sleepTime: sleepTime,
          wakeTime: wakeTime,
          durationHours: duration,
          wakeUpCount: i % 2 == 0 ? 0 : 1,
          feelingRating: 4,
          note: 'Ngủ ngon, cơ thể sảng khoái.',
          isGoalMet: duration >= 7.5,
          createdAt: day,
        ).toMap(),
      );
    }

    // Seed initial AI welcome message
    await db.insert(
      AppConstants.tableAIConversations,
      AIMessageModel(
        text: 'Xin chào! Tôi là Trợ lý AI Giấc ngủ DCSleep. Tôi có thể hỗ trợ bạn tìm hiểu về vệ sinh giấc ngủ, gợi ý kỹ thuật thư giãn và điều chỉnh thói quen ngủ khoa học. Hãy đặt câu hỏi cho tôi nhé!',
        isUser: false,
      ).toMap(),
    );
  }

  // --- Sleep Goal CRUD ---
  Future<SleepGoalModel> getSleepGoal() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query(AppConstants.tableSleepGoals, limit: 1);
      if (maps.isNotEmpty) {
        return SleepGoalModel.fromMap(maps.first);
      }
    }
    return SleepGoalModel(
      bedtimeHour: 23,
      bedtimeMinute: 0,
      wakeHour: 7,
      wakeMinute: 0,
      targetDurationHours: 8.0,
    );
  }

  Future<void> updateSleepGoal(SleepGoalModel goal) async {
    final db = await database;
    if (db == null) return;
    await db.delete(AppConstants.tableSleepGoals);
    await db.insert(AppConstants.tableSleepGoals, goal.toMap());
  }

  // --- Sleep Records CRUD ---
  Future<List<SleepRecordModel>> getSleepRecords({int limit = 30}) async {
    final db = await database;
    if (db == null) return [];
    final maps = await db.query(
      AppConstants.tableSleepRecords,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((e) => SleepRecordModel.fromMap(e)).toList();
  }

  Future<int> insertSleepRecord(SleepRecordModel record) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(AppConstants.tableSleepRecords, record.toMap());
  }

  // --- Nap Records CRUD ---
  Future<List<NapRecordModel>> getNapRecords({int limit = 20}) async {
    final db = await database;
    if (db == null) return [];
    final maps = await db.query(
      AppConstants.tableNapRecords,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((e) => NapRecordModel.fromMap(e)).toList();
  }

  Future<int> insertNapRecord(NapRecordModel nap) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(AppConstants.tableNapRecords, nap.toMap());
  }

  // --- Reminders CRUD ---
  Future<List<ReminderModel>> getReminders() async {
    final db = await database;
    if (db == null) {
      return [
        ReminderModel(title: 'Chuẩn bị đi ngủ (tắt điện thoại)', hour: 22, minute: 30, type: 'prepare_sleep'),
        ReminderModel(title: 'Đến giờ ngủ mục tiêu', hour: 23, minute: 0, type: 'bedtime'),
        ReminderModel(title: 'Thức dậy đón ngày mới', hour: 7, minute: 0, type: 'wakeup'),
      ];
    }
    final maps = await db.query(AppConstants.tableReminders);
    return maps.map((e) => ReminderModel.fromMap(e)).toList();
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      AppConstants.tableReminders,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // --- AI Messages CRUD ---
  Future<List<AIMessageModel>> getAIMessages() async {
    final db = await database;
    if (db == null) {
      return [
        AIMessageModel(
          text: 'Xin chào! Tôi là Trợ lý AI Giấc ngủ DCSleep. Tôi có thể hỗ trợ bạn tìm hiểu về vệ sinh giấc ngủ, gợi ý kỹ thuật thư giãn và điều chỉnh thói quen ngủ khoa học. Hãy đặt câu hỏi cho tôi nhé!',
          isUser: false,
        ),
      ];
    }
    final maps = await db.query(
      AppConstants.tableAIConversations,
      orderBy: 'timestamp ASC',
    );
    return maps.map((e) => AIMessageModel.fromMap(e)).toList();
  }

  Future<int> insertAIMessage(AIMessageModel msg) async {
    final db = await database;
    if (db == null) return 0;
    return await db.insert(AppConstants.tableAIConversations, msg.toMap());
  }

  // Alias for getAIMessages
  Future<List<AIMessageModel>> getAllAIMessages() => getAIMessages();

  Future<int> clearAllAIMessages() async {
    final db = await database;
    if (db == null) return 0;
    return await db.delete(AppConstants.tableAIConversations);
  }

  // --- Users Auth CRUD ---
  static final List<UserModel> _fallbackUsers = [
    UserModel(
      id: 1,
      name: 'Mã Khánh Linh',
      email: 'mkl.deeptry@gmail.com',
      studentId: '2351170602',
      className: '65KTPM',
    ),
  ];

  Future<UserModel?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final db = await database;
    if (db == null) {
      for (final u in _fallbackUsers) {
        if (u.email.toLowerCase() == normalizedEmail) return u;
      }
      return null;
    }
    final maps = await db.query(
      AppConstants.tableUsers,
      where: 'LOWER(email) = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> registerUser(UserModel user) async {
    final db = await database;
    if (db == null) {
      final newUser = UserModel(
        id: _fallbackUsers.length + 1,
        name: user.name,
        email: user.email,
        studentId: user.studentId,
        className: user.className,
        createdAt: user.createdAt,
      );
      _fallbackUsers.add(newUser);
      return newUser.id!;
    }
    return await db.insert(AppConstants.tableUsers, user.toMap());
  }
}
