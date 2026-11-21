import 'package:equatable/equatable.dart';

/// Loại ghi chú: ghi chú thường hoặc nhật ký hằng ngày.
enum NoteKind {
  note,
  diary;

  static NoteKind fromStorage(String value) {
    return value == NoteKind.diary.name ? NoteKind.diary : NoteKind.note;
  }
}

/// Entity ghi chú — Dart thuần, không phụ thuộc Flutter/Drift/Firebase.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.subjectId,
    this.tags = const <String>[],
  });

  final String id;
  final String title;
  final String content;
  final NoteKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? subjectId;
  final List<String> tags;

  bool get isDiary => kind == NoteKind.diary;

  String get displayTitle =>
      title.trim().isEmpty ? '(Chưa có tiêu đề)' : title.trim();

  Note copyWith({
    String? title,
    String? content,
    NoteKind? kind,
    DateTime? updatedAt,
    String? subjectId,
    List<String>? tags,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      kind: kind ?? this.kind,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subjectId: subjectId ?? this.subjectId,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    content,
    kind,
    createdAt,
    updatedAt,
    subjectId,
    tags,
  ];
}
