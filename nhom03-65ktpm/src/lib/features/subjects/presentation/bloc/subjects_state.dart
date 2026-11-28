import 'package:equatable/equatable.dart';

import '../../domain/entities/classified_note.dart';
import '../../domain/entities/note_filter.dart';
import '../../domain/entities/subject.dart';

enum SubjectsStatus { initial, loading, success, failure }

class SubjectsState extends Equatable {
  const SubjectsState({
    this.status = SubjectsStatus.initial,
    this.subjects = const <Subject>[],
    this.notes = const <ClassifiedNote>[],
    this.filter = NoteFilter.all,
    this.errorMessage,
  });

  final SubjectsStatus status;
  final List<Subject> subjects;
  final List<ClassifiedNote> notes;
  final NoteFilter filter;
  final String? errorMessage;

  bool get isLoading => status == SubjectsStatus.loading;

  /// Mọi tag đang được dùng trong các ghi chú, sắp xếp theo bảng chữ cái.
  List<String> get tags {
    final all = <String>{for (final note in notes) ...note.tags}.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    return all;
  }

  /// Ghi chú khớp bộ lọc hiện tại.
  List<ClassifiedNote> get visibleNotes => filter.apply(notes);

  Subject? subjectById(String? id) {
    for (final subject in subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  SubjectsState copyWith({
    SubjectsStatus? status,
    List<Subject>? subjects,
    List<ClassifiedNote>? notes,
    NoteFilter? filter,
    String? errorMessage,
  }) {
    return SubjectsState(
      status: status ?? this.status,
      subjects: subjects ?? this.subjects,
      notes: notes ?? this.notes,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    subjects,
    notes,
    filter,
    errorMessage,
  ];
}
