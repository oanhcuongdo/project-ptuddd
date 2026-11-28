import 'dart:async';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/notes_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/utils/uuid_format.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/remote/notes_remote_data_source.dart';
import '../models/note_mapper.dart';
import '../sync/note_sync_rules.dart';

/// Drift ghi trước, Supabase hợp nhất theo mốc cập nhật và lưu phiên bản thua.
class SyncedNoteRepository implements NoteRepository {
  SyncedNoteRepository({
    required this.daoForUser,
    required this.remote,
    required this.currentUserId,
    required this.monitor,
    this.retryDelay = const Duration(seconds: 5),
  });

  final NotesDao Function(String?) daoForUser;
  final NotesRemoteDataSource remote;
  final String? Function() currentUserId;
  final SyncMonitor monitor;
  final Duration retryDelay;

  StreamSubscription<List<Note>>? _remoteSubscription;
  String? _activeUserId;
  Timer? _retry;
  Future<void> _pending = Future<void>.value();
  bool _disposed = false;

  bool _isCurrent(String userId) =>
      !_disposed && _activeUserId == userId && currentUserId() == userId;

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> start() => _enqueue(_start);

  Future<void> _start() async {
    if (_disposed) return;
    final userId = currentUserId();
    if (_activeUserId == userId && _remoteSubscription != null) return;

    _retry?.cancel();
    await _remoteSubscription?.cancel();
    _remoteSubscription = null;
    _activeUserId = userId;
    if (userId == null) {
      monitor.report(SyncStatus.disabled);
      return;
    }

    await _refresh(userId);
    if (!_isCurrent(userId)) return;
    try {
      _remoteSubscription = remote
          .watchNotes(userId)
          .listen(
            (snapshot) {
              unawaited(_enqueue(() => _sync(userId, (_) async => snapshot)));
            },
            onError: (Object error) => _onStreamFailure(userId, error),
            onDone: () => _onStreamFailure(
              userId,
              const DatabaseFailure('Mất kết nối đồng bộ.'),
            ),
          );
    } on Object catch (error) {
      _reportError(userId, error);
    }
  }

  Future<void> _refresh(String userId) =>
      _sync(userId, (_) => remote.fetchNotes(userId));

  void _onStreamFailure(String userId, Object error) {
    unawaited(
      _enqueue(() async {
        if (!_isCurrent(userId)) return;
        await _remoteSubscription?.cancel();
        _remoteSubscription = null;
        _reportError(userId, error);
      }),
    );
  }

  @override
  Stream<List<Note>> watchNotes() {
    final userId = currentUserId();
    unawaited(start());
    return daoForUser(userId)
        .watchAll()
        .where((_) => currentUserId() == userId)
        .map(_toNotes);
  }

  @override
  Future<List<Note>> getNotes() async {
    final userId = currentUserId();
    final rows = await daoForUser(userId).getAll();
    return currentUserId() == userId ? _toNotes(rows) : [];
  }

  @override
  Future<Note?> findById(String id) async {
    final userId = currentUserId();
    final row = await daoForUser(userId).findById(id);
    return currentUserId() == userId ? row?.toEntity() : null;
  }

  @override
  Future<void> createNote(Note note) async {
    final userId = currentUserId();
    final local = note.copyWith(updatedAt: storageTimestamp(note.updatedAt));
    await daoForUser(userId).insertNote(local.toCompanion());
    await _push(userId, local);
  }

  @override
  Future<void> updateNote(Note note) => _changeNote(note.id, (current) {
    return note.copyWith(
      updatedAt: _nextTimestamp(current.updatedAt, note.updatedAt),
    );
  });

  @override
  Future<void> deleteNote(String id) => _changeNote(id, (current) {
    final deletedAt = _nextTimestamp(current.updatedAt, DateTime.now());
    return current.copyWith(updatedAt: deletedAt, deletedAt: deletedAt);
  });

  Future<void> _changeNote(String id, Note Function(Note) revise) async {
    final userId = currentUserId();
    final dao = daoForUser(userId);
    final local = await dao.transaction(() async {
      final row = await dao.findById(id);
      if (row == null || row.deletedAt != null) {
        throw const DatabaseFailure('Không tìm thấy ghi chú để cập nhật.');
      }
      final note = revise(row.toEntity());
      await dao.updateNote(id, note.toUpdateCompanion());
      return note;
    });
    await _push(userId, local);
  }

  DateTime _nextTimestamp(DateTime previous, DateTime requested) {
    final candidate = storageTimestamp(requested);
    return candidate.isAfter(previous)
        ? candidate
        : previous.add(const Duration(seconds: 1));
  }

  Future<void> _push(String? userId, Note note) {
    if (userId == null) return Future<void>.value();
    return _enqueue(() async {
      if (_activeUserId != userId || _remoteSubscription == null) {
        await _start();
        return;
      }
      if (!_isCurrent(userId)) return;
      if (!isUuid(note.id)) {
        _reportLegacy(note);
        return;
      }
      monitor.report(SyncStatus.syncing);
      try {
        await remote
            .upsertNote(userId, note)
            .timeout(const Duration(seconds: 10));
        // Một bản realtime hoặc lần retry đối chiếu cả cache trước khi báo hết lỗi.
        if (_retry?.isActive != true && _isCurrent(userId)) {
          monitor.report(SyncStatus.synced);
        }
      } on Object catch (error) {
        _reportError(userId, error);
      }
    });
  }

  Future<void> _sync(
    String userId,
    Future<List<Note>> Function(String) load,
  ) async {
    if (!_isCurrent(userId)) return;
    monitor.report(SyncStatus.syncing);
    try {
      final remoteNotes = await load(userId)
          .timeout(const Duration(seconds: 10));
      if (!_isCurrent(userId)) return;
      final dao = daoForUser(userId);
      final local = _toNotes(await dao.getAllIncludingDeleted());
      final originals = {for (final note in local) note.id: note};
      final incoming = notesToApplyLocally(local: local, remote: remoteNotes);
      final outgoing = {
        for (final note in notesToPush(local: local, remote: remoteNotes))
          note.id: note,
      };
      // Đẩy bản máy thua để RPC giữ lịch sử trước khi thay nó trong cache.
      for (final note in incoming) {
        final previous = originals[note.id];
        if (previous != null && !sameNoteContent(previous, note)) {
          outgoing[note.id] = previous;
        }
      }
      Note? legacy;
      for (final note in outgoing.values) {
        if (!_isCurrent(userId)) return;
        if (!isUuid(note.id)) {
          legacy ??= note;
          continue;
        }
        await remote
            .upsertNote(userId, note)
            .timeout(const Duration(seconds: 10));
      }

      if (!_isCurrent(userId)) return;
      await dao.transaction(() async {
        for (final note in incoming) {
          final current = (await dao.findById(note.id))?.toEntity();
          final original = originals[note.id];
          // Save trên thiết bị khi request đang chờ phải được giữ để lần sau đẩy.
          if (current == null && original == null ||
              current != null &&
                  original != null &&
                  sameStorageTimestamp(current.updatedAt, original.updatedAt) &&
                  sameNoteContent(current, original)) {
            await dao.upsertNote(note.toSyncCompanion());
          }
        }
      });
      if (!_isCurrent(userId)) return;
      _retry?.cancel();
      if (legacy != null) {
        _reportLegacy(legacy);
      } else {
        monitor.report(SyncStatus.synced);
      }
    } on Object catch (error) {
      _reportError(userId, error);
    }
  }

  List<Note> _toNotes(List<NoteRow> rows) =>
      rows.map((row) => row.toEntity()).toList();

  void _reportLegacy(Note note) => monitor.report(
    SyncStatus.error,
    message: 'Ghi chú "${note.displayTitle}" có mã cũ nên chưa đồng bộ được.',
  );

  void _reportError(String userId, Object error) {
    if (!_isCurrent(userId)) return;
    monitor.report(
      SyncStatus.error,
      message: error is Failure
          ? error.message
          : 'Không đồng bộ được. Đang chờ thử lại…',
    );
    if (_retry?.isActive == true) return;
    _retry = Timer(retryDelay, () {
      unawaited(
        _enqueue(() async {
          if (!_isCurrent(userId)) return;
          if (_remoteSubscription == null) {
            await _start();
          } else {
            await _refresh(userId);
          }
        }),
      );
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    _retry?.cancel();
    await _remoteSubscription?.cancel();
    await _pending;
  }
}
