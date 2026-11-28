import '../entities/note.dart';

/// Hợp đồng truy cập ghi chú.
///
/// Tầng `domain` chỉ biết interface này; phần hiện thực (Drift, Supabase) nằm ở
/// `data/`. Nhờ vậy UI và usecase không phụ thuộc hạ tầng cụ thể.
abstract interface class NoteRepository {
  /// Theo dõi danh sách ghi chú (đã sắp xếp mới nhất trước).
  Stream<List<Note>> watchNotes();

  Future<List<Note>> getNotes();

  Future<Note?> findById(String id);

  /// Tạo ghi chú mới; nếu [id] đã tồn tại thì ghi đè.
  Future<void> createNote(Note note);

  Future<void> updateNote(Note note);

  /// Xoá mềm: giữ dữ liệu để đồng bộ về sau.
  Future<void> deleteNote(String id);
}
