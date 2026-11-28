import 'package:equatable/equatable.dart';

/// Môn học dùng để phân loại ghi chú — Dart thuần.
class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.deletedAt,
  });

  /// UUID, vì `notes.subject_id` trên Supabase là khoá ngoại kiểu `uuid`.
  final String id;
  final String name;

  /// Màu hiển thị dạng `#RRGGBB`; `null` thì dùng màu mặc định.
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Khác `null` khi môn đã bị xoá mềm (giữ lại để đồng bộ giữa các máy).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Subject copyWith({
    String? name,
    String? color,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    color,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
