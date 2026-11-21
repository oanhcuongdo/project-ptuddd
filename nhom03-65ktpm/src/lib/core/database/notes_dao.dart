import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'notes_dao.g.dart';

/// Truy cập bảng [Notes] — chỉ tầng `data` được dùng DAO này.
@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  /// Theo dõi toàn bộ ghi chú chưa bị xoá, mới cập nhật trước.
  Stream<List<NoteRow>> watchAll() {
    final query = select(notes)
      ..where((Notes t) => t.deletedAt.isNull())
      ..orderBy([(Notes t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }

  /// Lấy toàn bộ ghi chú chưa bị xoá (một lần).
  Future<List<NoteRow>> getAll() {
    final query = select(notes)
      ..where((Notes t) => t.deletedAt.isNull())
      ..orderBy([(Notes t) => OrderingTerm.desc(t.updatedAt)]);
    return query.get();
  }

  Future<NoteRow?> findById(String id) {
    return (select(
      notes,
    )..where((Notes t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertNote(NotesCompanion row) => into(notes).insert(row);

  Future<bool> updateNote(String id, NotesCompanion row) async {
    final affected = await (update(
      notes,
    )..where((Notes t) => t.id.equals(id))).write(row);
    return affected > 0;
  }

  /// Xoá mềm để không mất dữ liệu khi đồng bộ với Supabase.
  Future<bool> softDeleteNote(String id) {
    return updateNote(
      id,
      NotesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
