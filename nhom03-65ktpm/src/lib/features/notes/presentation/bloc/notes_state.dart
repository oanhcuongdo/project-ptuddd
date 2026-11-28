import 'package:equatable/equatable.dart';

import '../../../../core/sync/sync_status.dart';
import '../../domain/entities/note.dart';

enum NotesStatus { initial, loading, success, failure }

class NotesState extends Equatable {
  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const <Note>[],
    this.errorMessage,
    this.syncStatus = SyncStatus.disabled,
    this.syncMessage,
  });

  final NotesStatus status;
  final List<Note> notes;
  final String? errorMessage;

  /// Trạng thái đồng bộ đa thiết bị (#21) — hiển thị ở AppBar.
  final SyncStatus syncStatus;

  /// Thông điệp lỗi đồng bộ gần nhất (nếu có).
  final String? syncMessage;

  bool get isLoading => status == NotesStatus.loading;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    String? errorMessage,
    SyncStatus? syncStatus,
    String? syncMessage,
    bool clearSyncMessage = false,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      errorMessage: errorMessage,
      syncStatus: syncStatus ?? this.syncStatus,
      syncMessage: clearSyncMessage ? null : (syncMessage ?? this.syncMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    notes,
    errorMessage,
    syncStatus,
    syncMessage,
  ];
}
