import '../../domain/entities/subject.dart';

/// Tên bảng trên Supabase — xem `docs/co_so_du_lieu.md` mục 4.
const String kSubjectsTable = 'subjects';

/// Chuyển [Subject] thành payload cho bảng `subjects`.
Map<String, dynamic> subjectToRemoteJson({
  required String userId,
  required Subject subject,
}) {
  return <String, dynamic>{
    'id': subject.id,
    'user_id': userId,
    'name': subject.name,
    'color': subject.color,
    'created_at': subject.createdAt.toUtc().toIso8601String(),
    'updated_at': subject.updatedAt.toUtc().toIso8601String(),
    'deleted_at': subject.deletedAt?.toUtc().toIso8601String(),
  };
}

/// Đọc một dòng bảng `subjects` thành entity (mốc thời gian về giờ máy).
Subject subjectFromRemoteRow(Map<String, dynamic> row) {
  return Subject(
    id: row['id'] as String,
    name: (row['name'] as String?) ?? '',
    color: row['color'] as String?,
    createdAt: _parseTime(row['created_at']) ?? DateTime.now(),
    updatedAt: _parseTime(row['updated_at']) ?? DateTime.now(),
    deletedAt: _parseTime(row['deleted_at']),
  );
}

DateTime? _parseTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
