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

  /// Lấy **cả** bản ghi đã xoá mềm — cần cho bước hợp nhất khi đồng bộ (#21),
  /// vì tombstone phải được so sánh như mọi bản ghi khác.
  Future<List<NoteRow>> getAllIncludingDeleted() {
    return select(notes).get();
  }

  Future<NoteRow?> findById(String id) {
    return (select(
      notes,
    )..where((Notes t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertNote(NotesCompanion row) => into(notes).insert(row);

  /// Ghi đè theo khoá chính — dùng khi áp thay đổi từ máy chủ xuống.
  Future<void> upsertNote(NotesCompanion row) =>
      into(notes).insertOnConflictUpdate(row);

  /// Ghi nhiều bản ghi trong một transaction.
  Future<void> upsertAll(Iterable<NotesCompanion> rows) async {
    final companions = rows.toList();
    if (companions.isEmpty) {
      return;
    }
    await batch((Batch b) {
      b.insertAllOnConflictUpdate(notes, companions);
    });
  }

  Future<bool> updateNote(String id, NotesCompanion row) async {
    final affected = await (update(
      notes,
    )..where((Notes t) => t.id.equals(id))).write(row);
    return affected > 0;
  }

  /// Xoá mềm để không mất dữ liệu khi đồng bộ với Supabase.
  Future<bool> softDeleteNote(String id, {DateTime? at}) {
    final now = at ?? DateTime.now();
    return updateNote(
      id,
      NotesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}
