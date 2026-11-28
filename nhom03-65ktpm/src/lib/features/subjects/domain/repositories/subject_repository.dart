import '../entities/subject.dart';

/// Hợp đồng truy cập môn học; hiện thực (Drift + Supabase) nằm ở `data/`.
abstract interface class SubjectRepository {
  /// Theo dõi các môn chưa bị xoá, theo thứ tự tạo.
  Stream<List<Subject>> watchSubjects();

  Future<void> createSubject(Subject subject);

  Future<void> updateSubject(Subject subject);

  /// Xoá mềm môn học (giữ bản ghi để đồng bộ việc xoá sang máy khác).
  Future<void> deleteSubject(String id);

  /// Đối chiếu môn trên máy với máy chủ: bản mới hơn thắng.
  /// Không cấu hình máy chủ thì không làm gì.
  Future<void> syncWithServer();
}
