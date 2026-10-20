import 'package:drift/drift.dart';
import 'tables/subjects_table.dart';
import 'tables/documents_table.dart';
import 'tables/delete_logs_table.dart';
import 'tables/app_settings_table.dart';
import 'daos/document_dao.dart';
import 'daos/subject_dao.dart';
import 'daos/delete_log_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Subjects, Documents, DeleteLogs, AppSettings],
  daos: [DocumentDao, SubjectDao, DeleteLogDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );
}
