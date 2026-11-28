import '../../../domain/entities/subject.dart';

/// Hợp đồng đọc/ghi môn học trên máy chủ dùng chung (Supabase).
///
/// Tách interface để test và chế độ không cấu hình Supabase không phụ thuộc
/// `supabase_flutter`.
abstract interface class SubjectsRemoteDataSource {
  /// Tải mọi môn của [userId], kể cả môn đã xoá mềm.
  Future<List<Subject>> fetchSubjects(String userId);

  /// Ghi đè một môn theo `id`; xoá mềm cũng đi qua đây.
  Future<void> upsertSubject(String userId, Subject subject);
}
