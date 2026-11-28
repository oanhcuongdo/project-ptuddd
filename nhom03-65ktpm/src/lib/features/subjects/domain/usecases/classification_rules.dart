import '../../../../core/error/failure.dart';
import '../entities/subject.dart';

/// Quy tắc kiểm tra tên môn học và tag trước khi lưu.
abstract final class ClassificationRules {
  static const int maxNameLength = 40;

  /// Bỏ khoảng trắng thừa: "  Toán   cao cấp " -> "Toán cao cấp".
  static String normalizeName(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Tag cho phép gõ kèm dấu `#`: "#ôn thi" -> "ôn thi".
  static String normalizeTag(String raw) =>
      normalizeName(raw.trim().replaceFirst(RegExp(r'^#+'), ''));

  /// Trả về tên môn đã chuẩn hoá, hoặc ném [ValidationFailure] nếu tên trống,
  /// quá dài hay trùng với môn khác (không phân biệt hoa thường).
  static String validateSubjectName(
    String raw,
    Iterable<Subject> existing, {
    String? exceptId,
  }) {
    final name = normalizeName(raw);
    _checkLength(name, 'môn học');
    final key = name.toLowerCase();
    final duplicated = existing.any(
      (Subject s) => s.id != exceptId && s.name.toLowerCase() == key,
    );
    if (duplicated) {
      throw ValidationFailure('Môn học "$name" đã có.');
    }
    return name;
  }

  /// Trả về tag đã chuẩn hoá, hoặc ném [ValidationFailure].
  ///
  /// Tag không được chứa dấu phẩy vì bảng `notes` lưu tag phân tách bằng dấu phẩy.
  static String validateTag(String raw) {
    final tag = normalizeTag(raw);
    _checkLength(tag, 'tag');
    if (tag.contains(',')) {
      throw const ValidationFailure('Tag không được chứa dấu phẩy.');
    }
    return tag;
  }

  /// Chuẩn hoá danh sách tag của một ghi chú: kiểm tra từng tag và bỏ tag trùng
  /// (không phân biệt hoa thường), giữ thứ tự xuất hiện đầu tiên.
  static List<String> normalizeTagList(Iterable<String> raw) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in raw) {
      final tag = validateTag(item);
      if (seen.add(tag.toLowerCase())) result.add(tag);
    }
    return result;
  }

  static void _checkLength(String name, String what) {
    if (name.isEmpty) {
      throw ValidationFailure('Tên $what không được để trống.');
    }
    if (name.length > maxNameLength) {
      throw ValidationFailure('Tên $what tối đa $maxNameLength ký tự.');
    }
  }
}
