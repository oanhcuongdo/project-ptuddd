import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/delete_logs_table.dart';

part 'delete_log_dao.g.dart';

@DriftAccessor(tables: [DeleteLogs])
class DeleteLogDao extends DatabaseAccessor<AppDatabase> with _$DeleteLogDaoMixin {
  DeleteLogDao(super.db);

  Stream<List<DeleteLog>> watchAllDeleteLogs() {
    return (select(deleteLogs)
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeModified, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<DeleteLog>> getAllDeleteLogs() => select(deleteLogs).get();

  Future<int> insertDeleteLog(Insertable<DeleteLog> log) => into(deleteLogs).insert(log);

  Future<List<DeleteLog>> getLogsSince(DateTime timestamp) {
    return (select(deleteLogs)
          ..where((tbl) => tbl.dateTimeModified.isBiggerOrEqualValue(timestamp)))
        .get();
  }

  Future<int> clearDeleteLogs() => delete(deleteLogs).go();
}
