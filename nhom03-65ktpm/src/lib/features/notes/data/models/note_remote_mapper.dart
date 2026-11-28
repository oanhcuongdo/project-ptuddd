import '../../../../core/utils/uuid_format.dart';
import '../../domain/entities/note.dart';

/// Tên bảng trên Supabase — xem `docs/co_so_du_lieu.md` mục 4.
const String kNotesTable = 'notes';

/// Chuyển [Note] thành payload cho bảng `notes`.
///
/// `subject_id` là `uuid` ở Postgres; nếu [Note.subjectId] không phải UUID thì
/// gửi `null` (chưa có tính năng môn học nên hiện luôn `null`) thay vì để
/// request hỏng.
Map<String, dynamic> noteToRemoteJson({
  required String userId,
  required Note note,
}) {
  return <String, dynamic>{
    'id': note.id,
    'user_id': userId,
    'title': note.title,
    'content': note.content,
    'subject_id': isUuid(note.subjectId) ? note.subjectId : null,
    'tags': note.tags,
    'kind': note.kind.name,
    'created_at': note.createdAt.toUtc().toIso8601String(),
    'updated_at': note.updatedAt.toUtc().toIso8601String(),
    'deleted_at': note.deletedAt?.toUtc().toIso8601String(),
  };
}

/// Đọc một dòng bảng `notes` thành entity.
///
/// Mốc thời gian trên Supabase là `timestamptz` (chuỗi ISO), chuyển về giờ máy
/// để so sánh với dữ liệu Drift bằng cùng một mốc thời gian thực.
Note noteFromRemoteRow(Map<String, dynamic> row) {
  final List<String> tags =
      (row['tags'] as List<dynamic>?)
          ?.whereType<String>()
          .where((String tag) => tag.trim().isNotEmpty)
          .toList() ??
      const <String>[];

  return Note(
    id: row['id'] as String,
    title: (row['title'] as String?) ?? '',
    content: (row['content'] as String?) ?? '',
    kind: NoteKind.fromStorage((row['kind'] as String?) ?? 'note'),
    createdAt: _parseTime(row['created_at']) ?? DateTime.now(),
    updatedAt: _parseTime(row['updated_at']) ?? DateTime.now(),
    subjectId: row['subject_id'] as String?,
    tags: tags,
    deletedAt: _parseTime(row['deleted_at']),
  );
}

DateTime? _parseTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
