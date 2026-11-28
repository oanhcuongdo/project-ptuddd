import 'package:equatable/equatable.dart';

import 'classified_note.dart';

/// Bộ lọc danh sách ghi chú theo môn học và tag.
///
/// - Môn học: tất cả, một môn cụ thể, hoặc chỉ ghi chú chưa phân loại.
/// - Tag: ghi chú phải có **đủ** các tag đã chọn (chọn thêm tag để thu hẹp).
class NoteFilter extends Equatable {
  const NoteFilter({
    this.subjectId,
    this.unclassifiedOnly = false,
    this.tags = const <String>{},
  }) : assert(subjectId == null || !unclassifiedOnly);

  static const NoteFilter all = NoteFilter();

  final String? subjectId;
  final bool unclassifiedOnly;
  final Set<String> tags;

  bool get isEmpty => subjectId == null && !unclassifiedOnly && tags.isEmpty;

  /// Chọn một môn (`null` = tất cả môn), giữ nguyên các tag đang lọc.
  NoteFilter withSubject(String? subjectId) =>
      NoteFilter(subjectId: subjectId, tags: tags);

  /// Chỉ hiện ghi chú chưa gán môn, giữ nguyên các tag đang lọc.
  NoteFilter withUnclassifiedOnly() =>
      NoteFilter(unclassifiedOnly: true, tags: tags);

  /// Bật/tắt một tag trong bộ lọc.
  NoteFilter toggleTag(String tag) {
    final next = Set<String>.of(tags);
    if (!next.remove(tag)) next.add(tag);
    return NoteFilter(
      subjectId: subjectId,
      unclassifiedOnly: unclassifiedOnly,
      tags: Set<String>.unmodifiable(next),
    );
  }

  NoteFilter clearTags() =>
      NoteFilter(subjectId: subjectId, unclassifiedOnly: unclassifiedOnly);

  /// Bỏ khỏi bộ lọc những môn/tag không còn tồn tại (sau khi bị xoá, đổi tên).
  NoteFilter retainExisting(Set<String> subjectIds, Set<String> existingTags) {
    final keptSubject = subjectId != null && subjectIds.contains(subjectId)
        ? subjectId
        : null;
    return NoteFilter(
      subjectId: keptSubject,
      unclassifiedOnly: unclassifiedOnly,
      tags: Set<String>.unmodifiable(tags.where(existingTags.contains)),
    );
  }

  bool matches(ClassifiedNote note) {
    if (unclassifiedOnly && note.subjectId != null) return false;
    if (subjectId != null && note.subjectId != subjectId) return false;
    return note.tags.toSet().containsAll(tags);
  }

  List<ClassifiedNote> apply(Iterable<ClassifiedNote> notes) {
    if (isEmpty) return notes.toList();
    return notes.where(matches).toList();
  }

  @override
  List<Object?> get props => <Object?>[subjectId, unclassifiedOnly, tags];
}
