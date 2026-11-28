import '../entities/classified_note.dart';

/// Hợp đồng gán môn học, tag cho ghi chú.
///
/// Theo thiết kế CSDL, tag nằm ngay trong ghi chú (`notes.tags`), không có bảng
/// riêng: tag được tạo khi gán cho ghi chú, đổi tên và xoá thì áp dụng cho mọi
/// ghi chú đang có tag đó.
abstract interface class NoteClassificationRepository {
  /// Theo dõi ghi chú chưa bị xoá cùng môn học, tag của chúng.
  Stream<List<ClassifiedNote>> watchNotes();

  /// Đặt môn học ([subjectId] = `null` để bỏ gán) và toàn bộ tag của ghi chú.
  Future<void> classifyNote(
    String noteId, {
    required String? subjectId,
    required List<String> tags,
  });

  /// Đổi tên tag trên mọi ghi chú; nếu ghi chú đã có [to] thì gộp làm một.
  Future<void> renameTag(String from, String to);

  /// Gỡ tag khỏi mọi ghi chú.
  Future<void> deleteTag(String tag);

  /// Chuyển mọi ghi chú thuộc môn [subjectId] về "chưa phân loại".
  Future<void> clearSubject(String subjectId);
}
