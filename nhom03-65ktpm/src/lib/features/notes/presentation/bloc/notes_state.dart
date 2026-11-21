import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';

enum NotesStatus { initial, loading, success, failure }

class NotesState extends Equatable {
  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const <Note>[],
    this.errorMessage,
  });

  final NotesStatus status;
  final List<Note> notes;
  final String? errorMessage;

  bool get isLoading => status == NotesStatus.loading;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    String? errorMessage,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, notes, errorMessage];
}
