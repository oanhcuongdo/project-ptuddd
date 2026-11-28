import '../../features/notes/domain/entities/note.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/subjects/domain/entities/classified_note.dart';
import '../../features/subjects/domain/repositories/note_classification_repository.dart';
import '../error/failure.dart';

/// Nối feature subjects với ghi chú qua [NoteRepository] của feature notes.
///
/// Gán môn/tag đi qua cùng luồng lưu và đồng bộ Supabase như khi sửa ghi chú,
/// nên không bị bản trên máy chủ ghi đè. Đặt ở `core/di` vì các feature không
/// được import chéo nhau.
class NoteClassificationAdapter implements NoteClassificationRepository {
  NoteClassificationAdapter(this._notes);

  final NoteRepository _notes;

  @override
  Stream<List<ClassifiedNote>> watchNotes() {
    return _notes.watchNotes().map(
      (List<Note> notes) => notes.map(_toClassified).toList(),
    );
  }

  @override
  Future<void> classifyNote(
    String noteId, {
    required String? subjectId,
    required List<String> tags,
  }) async {
    final note = await _notes.findById(noteId);
    if (note == null) {
      throw const DatabaseFailure('Không tìm thấy ghi chú để phân loại');
    }
    await _notes.updateNote(_classified(note, subjectId, tags));
  }

  @override
  Future<void> renameTag(String from, String to) {
    return _updateWhere(
      (Note note) => note.tags.contains(from),
      (Note note) => _classified(
        note,
        note.subjectId,
        _withoutDuplicates(note.tags.map((String t) => t == from ? to : t)),
      ),
    );
  }

  @override
  Future<void> deleteTag(String tag) {
    return _updateWhere(
      (Note note) => note.tags.contains(tag),
      (Note note) => _classified(
        note,
        note.subjectId,
        note.tags.where((String t) => t != tag).toList(),
      ),
    );
  }

  @override
  Future<void> clearSubject(String subjectId) {
    return _updateWhere(
      (Note note) => note.subjectId == subjectId,
      (Note note) => _classified(note, null, note.tags),
    );
  }

  Future<void> _updateWhere(
    bool Function(Note note) test,
    Note Function(Note note) change,
  ) async {
    for (final note in await _notes.getNotes()) {
      if (test(note)) await _notes.updateNote(change(note));
    }
  }

  static ClassifiedNote _toClassified(Note note) {
    return ClassifiedNote(
      id: note.id,
      title: note.title,
      subjectId: note.subjectId,
      tags: note.tags,
    );
  }

  /// `Note.copyWith` không xoá được `subjectId` (truyền `null` nghĩa là giữ
  /// nguyên), nên tạo bản mới với môn và tag cần đặt.
  static Note _classified(Note note, String? subjectId, List<String> tags) {
    return Note(
      id: note.id,
      title: note.title,
      content: note.content,
      kind: note.kind,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      subjectId: subjectId,
      tags: List<String>.unmodifiable(tags),
      deletedAt: note.deletedAt,
    );
  }

  static List<String> _withoutDuplicates(Iterable<String> tags) {
    final seen = <String>{};
    return tags.where((String t) => seen.add(t.toLowerCase())).toList();
  }
}
