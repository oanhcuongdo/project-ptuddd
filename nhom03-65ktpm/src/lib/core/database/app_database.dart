import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Cơ sở dữ liệu cục bộ (SQLite qua Drift) — cache offline của ứng dụng.
///
/// Nguồn dữ liệu chính là Supabase; Drift giữ bản sao để dùng khi mất mạng.
@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  /// [executor] chỉ dùng cho test (ví dụ `NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'smart_note'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
