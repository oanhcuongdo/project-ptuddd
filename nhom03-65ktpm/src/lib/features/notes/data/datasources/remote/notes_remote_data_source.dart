import '../../../domain/entities/note.dart';

/// Hợp đồng đọc/ghi ghi chú trên máy chủ dùng chung.
///
/// Tách interface để test và chế độ demo không cần Supabase thật, đồng thời
/// giữ tầng `data` không rò rỉ kiểu dữ liệu của `supabase_flutter` lên trên.
abstract interface class NotesRemoteDataSource {
  /// Tải toàn bộ ghi chú (kể cả tombstone) của [userId] — dùng cho lần đồng bộ
  /// đầu tiên hoặc khi có màn hình mới mở.
  Future<List<Note>> fetchNotes(String userId);

  /// Theo dõi thay đổi realtime của bảng `notes` theo [userId].
  Stream<List<Note>> watchNotes(String userId);

  /// Ghi đè một ghi chú (upsert theo `id`). Tombstone cũng đi qua đây.
  Future<void> upsertNote(String userId, Note note);
}
