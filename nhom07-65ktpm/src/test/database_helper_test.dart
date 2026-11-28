import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dcsleep/core/constants/app_constants.dart';
import 'package:dcsleep/data/database/database_helper.dart';
import 'package:dcsleep/data/models/ai_message_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeDatabase();
  });

  group('DatabaseHelper Version & In-Memory Tests', () {
    test('Database version is 2 in AppConstants and DatabaseHelper', () {
      expect(AppConstants.dbVersion, 2);
      expect(DatabaseHelper.databaseVersion, 2);
    });

    test('DatabaseHelper seeds 1 default welcome message on creation', () async {
      await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
      final messages = await DatabaseHelper.instance.getAllAIMessages();
      expect(messages.length, 1);
      expect(messages.first.isUser, false);
      expect(messages.first.text, contains('Xin chào! Tôi là Trợ lý AI Giấc ngủ DCSleep'));
      expect(messages.first.isOffline, false);
    });

    test('DatabaseHelper saves and retrieves is_offline flag using in-memory db', () async {
      await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
      final msg = AIMessageModel(
        text: 'Offline test',
        isUser: false,
        isOffline: true,
        timestamp: DateTime.now(),
      );
      final id = await DatabaseHelper.instance.insertAIMessage(msg);
      final messages = await DatabaseHelper.instance.getAllAIMessages();
      expect(messages.any((m) => m.id == id && m.isOffline == true), true);
    });

    test('DatabaseHelper clearAllAIMessages deletes all messages in the table', () async {
      await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
      // Ban đầu có 1 tin nhắn chào mặc định, chèn thêm 2 tin nhắn mới
      await DatabaseHelper.instance.insertAIMessage(
        AIMessageModel(text: 'Msg 1', isUser: true, timestamp: DateTime.now()),
      );
      await DatabaseHelper.instance.insertAIMessage(
        AIMessageModel(text: 'Msg 2', isUser: false, timestamp: DateTime.now()),
      );

      var messages = await DatabaseHelper.instance.getAllAIMessages();
      expect(messages.length, 3); // 1 default + 2 new

      // Xóa toàn bộ
      await DatabaseHelper.instance.clearAllAIMessages();
      messages = await DatabaseHelper.instance.getAllAIMessages();
      expect(messages.isEmpty, true);
    });

    test('DatabaseHelper onUpgrade properly migrates v1 database to v2 with is_offline column', () async {
      // Step 1: Tạo DB giả lập phiên bản v1 (chỉ có id, text, is_user, timestamp)
      final v1Db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${AppConstants.tableAIConversations} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              text TEXT NOT NULL,
              is_user INTEGER NOT NULL,
              timestamp TEXT NOT NULL
            )
          ''');
          // Chèn 1 tin nhắn thời v1 (không có cột is_offline)
          await db.insert(AppConstants.tableAIConversations, {
            'text': 'Tin nhắn từ phiên bản v1 cũ',
            'is_user': 1,
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
      );

      // Xác nhận bảng v1 lúc này CHƯA có cột is_offline
      final initialCols = await v1Db.rawQuery('PRAGMA table_info(${AppConstants.tableAIConversations})');
      expect(initialCols.any((c) => c['name'] == 'is_offline'), false);

      // Step 2: Kích hoạt migration onUpgrade lên phiên bản 2
      await DatabaseHelper.instance.onUpgrade(v1Db, 1, 2);

      // Step 3: Kiểm tra cột is_offline đã được bổ sung thành công
      final upgradedCols = await v1Db.rawQuery('PRAGMA table_info(${AppConstants.tableAIConversations})');
      expect(upgradedCols.any((c) => c['name'] == 'is_offline'), true);

      // Step 4: Kiểm tra dữ liệu cũ vẫn nguyên vẹn và is_offline mặc định là 0
      final rows = await v1Db.query(AppConstants.tableAIConversations);
      expect(rows.length, 1);
      expect(rows.first['text'], 'Tin nhắn từ phiên bản v1 cũ');
      expect(rows.first['is_offline'], 0);

      // Step 5: Thử chèn tin nhắn mới với is_offline = 1 trên DB vừa nâng cấp
      await v1Db.insert(AppConstants.tableAIConversations, {
        'text': 'Tin nhắn v2 ngoại tuyến',
        'is_user': 0,
        'is_offline': 1,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final allRows = await v1Db.query(AppConstants.tableAIConversations, orderBy: 'id ASC');
      expect(allRows.length, 2);
      expect(allRows.last['is_offline'], 1);

      await v1Db.close();
    });

    test('closeDatabase cleans up connection and resets state cleanly', () async {
      await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
      await DatabaseHelper.instance.insertAIMessage(
        AIMessageModel(text: 'Temp message', isUser: true, timestamp: DateTime.now()),
      );
      await DatabaseHelper.instance.closeDatabase();

      // Mở lại DB mới hoàn toàn (in-memory) -> Chỉ có 1 tin chào mặc định, tin Temp đã mất
      await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
      final list = await DatabaseHelper.instance.getAllAIMessages();
      expect(list.length, 1);
      expect(list.first.text, contains('Xin chào'));
    });
  });
}
