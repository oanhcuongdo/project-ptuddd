import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/note.dart';

/// Chuyển đổi giữa model hạ tầng ([NoteRow]) và entity của domain.
///
/// Drift/Firebase/Supabase không được rò rỉ ra ngoài tầng `data`.
extension NoteRowMapper on NoteRow {
  Note toEntity() {
    return Note(
      id: id,
      title: title,
      content: content,
      kind: NoteKind.fromStorage(kind),
      createdAt: createdAt,
      updatedAt: updatedAt,
      subjectId: subjectId,
      tags: tags.isEmpty
          ? const <String>[]
          : tags
                .split(',')
                .map((String t) => t.trim())
                .where((String t) => t.isNotEmpty)
                .toList(),
      deletedAt: deletedAt,
    );
  }
}

extension NoteEntityMapper on Note {
  String get tagsAsStorage => tags.join(',');

  /// Dùng cho lệnh insert/upsert.
  NotesCompanion toCompanion() {
    return NotesCompanion.insert(
      id: id,
      title: Value<String>(title),
      content: Value<String>(content),
      subjectId: Value<String?>(subjectId),
      tags: Value<String>(tagsAsStorage),
      kind: Value<String>(kind.name),
      createdAt: Value<DateTime>(createdAt),
      updatedAt: Value<DateTime>(updatedAt),
      deletedAt: Value<DateTime?>(deletedAt),
    );
  }

  /// Dùng cho lệnh update (không đổi `createdAt`).
  NotesCompanion toUpdateCompanion() {
    return NotesCompanion(
      title: Value<String>(title),
      content: Value<String>(content),
      subjectId: Value<String?>(subjectId),
      tags: Value<String>(tagsAsStorage),
      kind: Value<String>(kind.name),
      updatedAt: Value<DateTime>(updatedAt),
      deletedAt: Value<DateTime?>(deletedAt),
    );
  }

  /// Bản ghi đầy đủ để ghi đè khi đồng bộ (kể cả tombstone).
  NotesCompanion toSyncCompanion() {
    return NotesCompanion(
      id: Value<String>(id),
      title: Value<String>(title),
      content: Value<String>(content),
      subjectId: Value<String?>(subjectId),
      tags: Value<String>(tagsAsStorage),
      kind: Value<String>(kind.name),
      createdAt: Value<DateTime>(createdAt),
      updatedAt: Value<DateTime>(updatedAt),
      deletedAt: Value<DateTime?>(deletedAt),
    );
  }
}
