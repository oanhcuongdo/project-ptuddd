import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_status.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import 'notes_state.dart';

/// Giữ danh sách ghi chú cho màn hình chính.
///
/// Widget không đọc database trực tiếp: mọi thứ đi qua cubit này.
class NotesCubit extends Cubit<NotesState> {
  NotesCubit(this._repository, {SyncMonitor? monitor})
    : super(NotesState(syncStatus: monitor?.status ?? SyncStatus.disabled)) {
    _syncSubscription = monitor?.stream.listen((SyncStatus status) {
      emit(
        state.copyWith(
          syncStatus: status,
          syncMessage: monitor.lastMessage,
          clearSyncMessage: monitor.lastMessage == null,
        ),
      );
    });
  }

  final NoteRepository _repository;
  StreamSubscription<List<Note>>? _subscription;
  StreamSubscription<SyncStatus>? _syncSubscription;

  /// Bắt đầu theo dõi dữ liệu; gọi một lần khi màn hình được tạo.
  Future<void> load() async {
    emit(state.copyWith(status: NotesStatus.loading, errorMessage: null));
    await _subscription?.cancel();
    _subscription = _repository.watchNotes().listen(
      (List<Note> notes) {
        emit(
          state.copyWith(
            status: NotesStatus.success,
            notes: notes,
            errorMessage: null,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: NotesStatus.failure,
            errorMessage: error is Failure ? error.message : '$error',
          ),
        );
      },
    );
  }

  Future<Note> createNote({
    required String title,
    required String content,
    NoteKind kind = NoteKind.note,
  }) async {
    final now = DateTime.now();
    final note = Note(
      // Bảng `notes` trên Supabase dùng khoá `uuid`, nên id sinh ngay trên máy
      // cũng phải là UUID v4 (#21).
      id: const Uuid().v4(),
      title: title,
      content: content,
      kind: kind,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.createNote(note);
    return note;
  }

  Future<void> updateNote(Note note, {String? title, String? content}) async {
    await _repository.updateNote(
      note.copyWith(title: title, content: content, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteNote(String id) => _repository.deleteNote(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _syncSubscription?.cancel();
    return super.close();
  }
}
