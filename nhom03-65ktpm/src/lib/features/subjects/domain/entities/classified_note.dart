import 'package:equatable/equatable.dart';

/// Ghi chú nhìn từ góc độ phân loại: chỉ gồm thông tin cần để lọc và gán
/// môn học, tag.
///
/// Feature này không import entity `Note` của feature notes (quy định không
/// import chéo giữa các feature); dữ liệu vẫn đọc từ cùng bảng `notes`.
class ClassifiedNote extends Equatable {
  const ClassifiedNote({
    required this.id,
    required this.title,
    this.subjectId,
    this.tags = const <String>[],
  });

  final String id;
  final String title;

  /// `null` nghĩa là ghi chú chưa thuộc môn nào.
  final String? subjectId;
  final List<String> tags;

  String get displayTitle =>
      title.trim().isEmpty ? '(Chưa có tiêu đề)' : title.trim();

  @override
  List<Object?> get props => <Object?>[id, title, subjectId, tags];
}
