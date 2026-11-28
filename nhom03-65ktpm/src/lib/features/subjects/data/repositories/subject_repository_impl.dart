import 'dart:async';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/subjects_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../datasources/remote/subjects_remote_data_source.dart';
import '../models/subject_mapper.dart';

/// Hiện thực [SubjectRepository]: lưu trên Drift, đẩy lên Supabase nếu có.
///
/// Môn học phải có trên Supabase trước khi ghi chú trỏ tới nó, vì
/// `notes.subject_id` là khoá ngoại tới bảng `subjects`.
class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl({
    required this.dao,
    this.remote,
    this.currentUserId = _noUser,
  });

  /// Lấy DAO tại thời điểm dùng, vì mỗi tài khoản có database riêng khi bật
  /// đồng bộ (xem `AppDependencies`).
  final SubjectsDao Function() dao;
  final SubjectsRemoteDataSource? remote;
  final String? Function() currentUserId;

  static String? _noUser() => null;

  @override
  Stream<List<Subject>> watchSubjects() {
    return dao().watchAll().map(
      (List<SubjectRow> rows) =>
          rows.map((SubjectRow row) => row.toEntity()).toList(),
    );
  }

  @override
  Future<void> createSubject(Subject subject) async {
    await _local(
      () => dao().insertSubject(subject.toCompanion()),
      'Không tạo được môn học',
    );
    await _push(subject);
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    await _local(() async {
      final updated = await dao().updateSubject(
        subject.id,
        subject.toUpdateCompanion(),
      );
      if (!updated) {
        throw const DatabaseFailure('Không tìm thấy môn học để cập nhật');
      }
    }, 'Không cập nhật được môn học');
    await _push(subject);
  }

  @override
  Future<void> deleteSubject(String id) async {
    final row = await dao().findById(id);
    if (row == null || row.deletedAt != null) {
      throw const DatabaseFailure('Không tìm thấy môn học để xoá');
    }
    final now = DateTime.now();
    await updateSubject(
      row.toEntity().copyWith(updatedAt: now, deletedAt: now),
    );
  }

  @override
  Future<void> syncWithServer() async {
    final server = remote;
    final userId = currentUserId();
    if (server == null || userId == null) return;
    try {
      final store = dao();
      final serverSubjects = await server
          .fetchSubjects(userId)
          .timeout(const Duration(seconds: 10));
      final local = <String, Subject>{
        for (final row in await store.getAllIncludingDeleted())
          row.id: row.toEntity(),
      };
      for (final incoming in serverSubjects) {
        final current = local.remove(incoming.id);
        // Bản mới hơn thắng; trên máy mới hơn thì đẩy lên.
        if (current == null || incoming.updatedAt.isAfter(current.updatedAt)) {
          await store.upsertSubject(incoming.toCompanion());
        } else if (current.updatedAt.isAfter(incoming.updatedAt)) {
          await server.upsertSubject(userId, current);
        }
      }
      // Môn chỉ có trên máy (tạo khi mất mạng) thì đẩy lên.
      for (final subject in local.values) {
        await server.upsertSubject(userId, subject);
      }
    } on Object catch (error) {
      throw DatabaseFailure('Chưa đồng bộ được môn học với máy chủ: $error');
    }
  }

  Future<void> _local(Future<void> Function() action, String message) async {
    try {
      await action();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DatabaseFailure('$message: $error');
    }
  }

  Future<void> _push(Subject subject) async {
    final server = remote;
    final userId = currentUserId();
    if (server == null || userId == null) return;
    try {
      await server
          .upsertSubject(userId, subject)
          .timeout(const Duration(seconds: 10));
    } on Object catch (error) {
      throw DatabaseFailure(
        'Đã lưu môn học trên máy nhưng chưa đồng bộ được lên máy chủ: $error',
      );
    }
  }
}
