import '../../domain/entities/note.dart';

/// Quy tắc hợp nhất dữ liệu giữa cache cục bộ (Drift) và máy chủ (Supabase).
///
/// Nguyên tắc: **bản có `updatedAt` mới hơn thắng**; nếu hai bên cùng mốc thời
/// gian nhưng nội dung khác nhau thì bản trên máy chủ thắng để mọi thiết bị hội
/// tụ về cùng một kết quả (không dao động ping-pong). Tombstone (`deletedAt`)
/// được đối xử như một thay đổi bình thường, nhờ vậy xoá trên máy A sẽ xoá trên
/// máy B thay vì bị \"hồi sinh\" bởi bản cũ còn sót.
///
/// Hàm thuần, không I/O — test được không cần Supabase.

/// Các bản ghi máy chủ cần ghi đè xuống cache cục bộ.
List<Note> notesToApplyLocally({
  required List<Note> local,
  required List<Note> remote,
}) {
  final Map<String, Note> localById = <String, Note>{
    for (final Note note in local) note.id: note,
  };
  final List<Note> result = <Note>[];
  for (final Note incoming in remote) {
    final Note? current = localById[incoming.id];
    if (current == null) {
      result.add(incoming);
      continue;
    }
    if (storageTimestamp(incoming.updatedAt)
        .isAfter(storageTimestamp(current.updatedAt))) {
      result.add(incoming);
    } else if (sameStorageTimestamp(incoming.updatedAt, current.updatedAt) &&
        !sameNoteContent(incoming, current)) {
      result.add(incoming);
    }
  }
  return result;
}

/// Các bản ghi cục bộ cần đẩy lên máy chủ.
List<Note> notesToPush({
  required List<Note> local,
  required List<Note> remote,
}) {
  final Map<String, Note> remoteById = <String, Note>{
    for (final Note note in remote) note.id: note,
  };
  final List<Note> result = <Note>[];
  for (final Note note in local) {
    final Note? onServer = remoteById[note.id];
    if (onServer == null ||
        storageTimestamp(note.updatedAt)
            .isAfter(storageTimestamp(onServer.updatedAt))) {
      result.add(note);
    } else if (sameStorageTimestamp(note.updatedAt, onServer.updatedAt) &&
        !sameNoteContent(note, onServer)) {
      // Máy chủ thắng khi hoà, nên bản cục bộ khác nội dung sẽ được áp lại
      // xuống (xem [notesToApplyLocally]) chứ không đẩy ngược lên.
      continue;
    }
  }
  return result;
}

bool sameNoteContent(Note a, Note b) {
  if (a.title != b.title || a.content != b.content || a.kind != b.kind) {
    return false;
  }
  if (a.subjectId != b.subjectId) {
    return false;
  }
  if ((a.deletedAt == null) != (b.deletedAt == null) ||
      (a.deletedAt != null &&
          !sameStorageTimestamp(a.deletedAt!, b.deletedAt!))) {
    return false;
  }
  if (a.tags.length != b.tags.length) {
    return false;
  }
  for (int i = 0; i < a.tags.length; i++) {
    if (a.tags[i] != b.tags[i]) {
      return false;
    }
  }
  return true;
}

/// Drift lưu DateTime theo giây. So ở cùng độ chính xác để một snapshot có
/// phần lẻ giây không ghi đè lại cache sau mỗi lần nhận.
DateTime storageTimestamp(DateTime timestamp) =>
    DateTime.fromMillisecondsSinceEpoch(
      timestamp.millisecondsSinceEpoch ~/ 1000 * 1000,
      isUtc: true,
    );

bool sameStorageTimestamp(DateTime a, DateTime b) =>
    storageTimestamp(a).isAtSameMomentAs(storageTimestamp(b));
