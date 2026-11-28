import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/subject.dart';

/// Chuyển đổi giữa model Drift ([SubjectRow]) và entity của domain.
extension SubjectRowMapper on SubjectRow {
  Subject toEntity() {
    return Subject(
      id: id,
      name: name,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension SubjectEntityMapper on Subject {
  /// Đủ mọi cột — dùng cho insert và khi áp bản từ máy chủ xuống.
  SubjectsCompanion toCompanion() {
    return SubjectsCompanion.insert(
      id: id,
      name: name,
      color: Value<String?>(color),
      createdAt: Value<DateTime>(createdAt),
      updatedAt: Value<DateTime>(updatedAt),
      deletedAt: Value<DateTime?>(deletedAt),
    );
  }

  /// Dùng cho update (không đổi `createdAt`).
  SubjectsCompanion toUpdateCompanion() {
    return SubjectsCompanion(
      name: Value<String>(name),
      color: Value<String?>(color),
      updatedAt: Value<DateTime>(updatedAt),
      deletedAt: Value<DateTime?>(deletedAt),
    );
  }
}
