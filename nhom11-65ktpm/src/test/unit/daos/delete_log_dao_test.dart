import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:study_material_manager/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Tầng Data Layer - DeleteLogDao (Tombstones) Tests', () {
    test('Ghi nhận và truy vấn Tombstones theo dấu thời gian', () async {
      final t1 = DateTime(2026, 10, 1, 10, 0);
      final t2 = DateTime(2026, 10, 2, 10, 0);

      await db.deleteLogDao.insertDeleteLog(
        DeleteLogsCompanion.insert(
          deleteLogPk: 'log-1',
          entryPk: 'doc-old-1',
          itemType: 'document',
          dateTimeModified: t1,
        ),
      );

      await db.deleteLogDao.insertDeleteLog(
        DeleteLogsCompanion.insert(
          deleteLogPk: 'log-2',
          entryPk: 'doc-old-2',
          itemType: 'document',
          dateTimeModified: t2,
        ),
      );

      final allLogs = await db.deleteLogDao.getAllDeleteLogs();
      expect(allLogs.length, equals(2));

      // Lọc các bản ghi từ thời điểm t2 trở đi
      final logsSince = await db.deleteLogDao.getLogsSince(t2);
      expect(logsSince.length, equals(1));
      expect(logsSince.first.entryPk, equals('doc-old-2'));
    });
  });
}
