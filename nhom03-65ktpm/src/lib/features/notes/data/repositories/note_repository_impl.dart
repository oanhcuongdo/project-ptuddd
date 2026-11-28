import '../../../../core/database/app_database.dart';
import '../../../../core/database/notes_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_mapper.dart';

/// Hiện thực [NoteRepository] trên cache cục bộ (Drift).
///
/// Sau này tầng này sẽ gộp thêm `datasources/remote` (Supabase) mà không đổi
/// interface của domain.
class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._dao);

  final NotesDao _dao;

  @override
  Stream<List<Note>> watchNotes() {
    return _dao.watchAll().map(
      (List<NoteRow> rows) =>
          rows.map((NoteRow row) => row.toEntity()).toList(),
    );
  }

  @override
  Future<List<Note>> getNotes() async {
    try {
      final rows = await _dao.getAll();
      return rows.map((row) => row.toEntity()).toList();
    } on Object catch (error) {
      throw DatabaseFailure('Không đọc được ghi chú: $error');
    }
  }

  @override
  Future<Note?> findById(String id) async {
    final row = await _dao.findById(id);
    return row?.toEntity();
  }

  @override
  Future<void> createNote(Note note) async {
    try {
      await _dao.insertNote(note.toCompanion());
    } on Object catch (error) {
      throw DatabaseFailure('Không tạo được ghi chú: $error');
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    try {
      final updated = await _dao.updateNote(note.id, note.toUpdateCompanion());
      if (!updated) {
        throw const DatabaseFailure('Không tìm thấy ghi chú để cập nhật');
      }
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DatabaseFailure('Không cập nhật được ghi chú: $error');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      final deleted = await _dao.softDeleteNote(id);
      if (!deleted) {
        throw const DatabaseFailure('Không tìm thấy ghi chú để xoá');
      }
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DatabaseFailure('Không xoá được ghi chú: $error');
    }
  }
}
