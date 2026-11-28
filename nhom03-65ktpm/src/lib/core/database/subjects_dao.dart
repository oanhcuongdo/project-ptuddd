import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'subjects_dao.g.dart';

/// Truy cập bảng [Subjects] — chỉ tầng `data` được dùng DAO này.
@DriftAccessor(tables: [Subjects])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  /// Theo dõi các môn chưa bị xoá, theo thứ tự tạo.
  Stream<List<SubjectRow>> watchAll() {
    final query = select(subjects)
      ..where((Subjects t) => t.deletedAt.isNull())
      ..orderBy([(Subjects t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  /// Mọi môn kể cả đã xoá mềm — dùng khi đối chiếu với Supabase.
  Future<List<SubjectRow>> getAllIncludingDeleted() => select(subjects).get();

  Future<SubjectRow?> findById(String id) {
    return (select(
      subjects,
    )..where((Subjects t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertSubject(SubjectsCompanion row) =>
      into(subjects).insert(row);

  /// Ghi đè theo `id` — dùng khi áp bản mới hơn từ máy chủ xuống.
  Future<void> upsertSubject(SubjectsCompanion row) =>
      into(subjects).insertOnConflictUpdate(row);

  Future<bool> updateSubject(String id, SubjectsCompanion row) async {
    final affected = await (update(
      subjects,
    )..where((Subjects t) => t.id.equals(id))).write(row);
    return affected > 0;
  }
}
