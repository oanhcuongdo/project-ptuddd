import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/core/sync/sync_status.dart';
import 'package:smart_note/features/notes/data/datasources/remote/notes_remote_data_source.dart';
import 'package:smart_note/features/notes/data/models/note_mapper.dart';
import 'package:smart_note/features/notes/data/repositories/synced_note_repository.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';

const String kNoteId = '3f0d5f4e-9f1a-4c7b-9d61-2a4f7f0b9c11';
const String kOtherId = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';

Note buildNote({
  String id = kNoteId,
  String title = 'Ghi chú',
  String content = 'nội dung',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  final DateTime created = DateTime(2026, 11, 25, 8);
  return Note(
    id: id,
    title: title,
    content: content,
    kind: NoteKind.note,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    deletedAt: deletedAt,
  );
}

class FakeNotesRemote implements NotesRemoteDataSource {
  final stores = <String, Map<String, Note>>{};
  Map<String, Note> storeFor(String uid) => stores.putIfAbsent(uid, () => {});
  Map<String, Note> get store => storeFor('uid-minh');
  final archived = <Note>[];
  final List<Note> pushed = <Note>[];
  final StreamController<List<Note>> controller =
      StreamController<List<Note>>.broadcast();

  Object? fetchError;
  Object? upsertError;

  @override
  Future<List<Note>> fetchNotes(String userId) async {
    final Object? error = fetchError;
    if (error != null) {
      throw error;
    }
    return storeFor(userId).values.toList();
  }

  @override
  Stream<List<Note>> watchNotes(String userId) => controller.stream;

  @override
  Future<void> upsertNote(String userId, Note note) async {
    final Object? error = upsertError;
    if (error != null) {
      throw error;
    }
    final notes = storeFor(userId);
    final saved = notes[note.id];
    if (saved == null || note.updatedAt.isAfter(saved.updatedAt)) {
      if (saved != null) archived.add(saved);
      notes[note.id] = note;
    } else if (saved.title != note.title || saved.content != note.content) {
      archived.add(note);
    }
    pushed.add(note);
  }

  void emitSnapshot() => controller.add(store.values.toList());

  Future<void> close() => controller.close();
}

void main() {
  late AppDatabase database;
  late NotesDao dao;
  late FakeNotesRemote remote;
  late SyncMonitor monitor;
  late SyncedNoteRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = NotesDao(database);
    remote = FakeNotesRemote();
    monitor = SyncMonitor(initial: SyncStatus.syncing);
    repository = SyncedNoteRepository(
      daoForUser: (_) => dao,
      remote: remote,
      currentUserId: () => 'uid-minh',
      monitor: monitor,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await remote.close();
    await monitor.dispose();
    await database.close();
  });

  test('tạo ghi chú: ghi máy trước rồi đẩy lên máy chủ', () async {
    await repository.start();

    await repository.createNote(buildNote(title: 'Mới'));

    final List<Note> localNotes = await repository.getNotes();
    expect(localNotes.single.title, 'Mới');
    expect(remote.pushed.single.title, 'Mới');
    expect(monitor.status, SyncStatus.synced);
  });

  test(
    'máy chủ lỗi khi đẩy: dữ liệu máy vẫn còn, chỉ báo chuyển lỗi',
    () async {
      await repository.start();
      remote.upsertError = Exception('mất mạng');

      await repository.createNote(buildNote(title: 'Ngoại tuyến'));

      expect((await repository.getNotes()).single.title, 'Ngoại tuyến');
      expect(monitor.status, SyncStatus.error);
    },
  );

  test('thay đổi realtime từ thiết bị khác được ghi xuống máy', () async {
    await repository.start();
    final DateTime later = DateTime(2026, 11, 25, 12);

    remote.store[kOtherId] = buildNote(
      id: kOtherId,
      title: 'Từ máy khác',
      updatedAt: later,
    );
    remote.emitSnapshot();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final List<Note> notes = await repository.getNotes();
    expect(notes.single.title, 'Từ máy khác');
  });

  test('bản máy mới hơn không bị bản máy chủ cũ ghi đè', () async {
    await repository.start();
    final DateTime newer = DateTime(2026, 11, 25, 13);
    await repository.createNote(buildNote(title: 'Bản máy', updatedAt: newer));

    remote.store[kNoteId] = buildNote(
      title: 'Bản chủ cũ',
      updatedAt: DateTime(2026, 11, 25, 9),
    );
    remote.emitSnapshot();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect((await repository.getNotes()).single.title, 'Bản máy');
  });

  test('tombstone từ máy chủ ẩn ghi chú trên máy', () async {
    await repository.start();
    await repository.createNote(buildNote());

    final DateTime deletedAt = DateTime(2026, 11, 25, 14);
    remote.store[kNoteId] = buildNote(
      updatedAt: deletedAt,
      deletedAt: deletedAt,
    );
    remote.emitSnapshot();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(await repository.getNotes(), isEmpty);
    // Bản ghi vẫn được giữ (xoá mềm) để không mất dữ liệu khi hợp nhất.
    expect((await dao.getAllIncludingDeleted()).single.deletedAt, isNotNull);
  });

  test('xoá ghi chú đẩy tombstone lên máy chủ', () async {
    await repository.start();
    await repository.createNote(buildNote());

    await repository.deleteNote(kNoteId);

    expect(remote.store[kNoteId]?.deletedAt, isNotNull);
    expect(await repository.getNotes(), isEmpty);
  });

  test('lần đồng bộ đầu đẩy các ghi chú chỉ có trên máy', () async {
    // Ghi thẳng vào Drift (như dữ liệu tạo trước khi bật Supabase).
    await dao.insertNote(buildNote(title: 'Chỉ trên máy').toCompanion());

    await repository.start();

    expect(remote.pushed.single.title, 'Chỉ trên máy');
  });

  test('lỗi tải dữ liệu không làm hỏng app, chỉ báo lỗi', () async {
    remote.fetchError = Exception('403');

    await repository.start();

    expect(monitor.status, SyncStatus.error);
    expect(await repository.getNotes(), isEmpty);
  });

  test('bản sửa offline không mất khi máy chủ có phiên bản mới hơn', () async {
    final old = buildNote(title: 'Máy không có mạng');
    await dao.insertNote(old.toCompanion());
    remote.store[kNoteId] = buildNote(
      title: 'Từ thiết bị khác',
      updatedAt: DateTime(2026, 11, 25, 13),
    );

    await repository.start();

    expect(remote.archived.single.title, old.title);
    expect((await repository.getNotes()).single.title, 'Từ thiết bị khác');
  });

  test('thử lại sau lỗi mạng và tự đẩy ghi chú đã lưu', () async {
    final retrying = SyncedNoteRepository(
      daoForUser: (_) => dao,
      remote: remote,
      currentUserId: () => 'uid-minh',
      monitor: monitor,
      retryDelay: const Duration(milliseconds: 15),
    );
    addTearDown(retrying.dispose);
    await retrying.start();
    remote.upsertError = Exception('mất mạng');
    await retrying.createNote(buildNote());
    expect(monitor.status, SyncStatus.error);

    remote.upsertError = null;
    await monitor.stream
        .firstWhere((s) => s == SyncStatus.synced)
        .timeout(const Duration(seconds: 2));
    expect(remote.store[kNoteId]?.title, 'Ghi chú');
  });

  test('đổi tài khoản không đọc hoặc đẩy ghi chú từ cache cũ', () async {
    final secondDb = AppDatabase(NativeDatabase.memory());
    final secondDao = NotesDao(secondDb);
    var uid = 'uid-minh';
    final scoped = SyncedNoteRepository(
      daoForUser: (account) => account == 'uid-minh' ? dao : secondDao,
      remote: remote,
      currentUserId: () => uid,
      monitor: monitor,
    );
    addTearDown(() async {
      await scoped.dispose();
      await secondDb.close();
    });
    await scoped.createNote(buildNote(title: 'Ghi chú của Minh'));

    uid = 'uid-khac';
    await scoped.start();
    expect(await scoped.getNotes(), isEmpty);
    expect(remote.storeFor(uid), isEmpty);

    uid = 'uid-minh';
    await scoped.start();
    expect((await scoped.getNotes()).single.title, 'Ghi chú của Minh');
  });

  test(
    'hai thiết bị nhận cập nhật và giữ phiên bản thua khi cùng sửa',
    () async {
      final secondDb = AppDatabase(NativeDatabase.memory());
      final secondDao = NotesDao(secondDb);
      final second = SyncedNoteRepository(
        daoForUser: (_) => secondDao,
        remote: remote,
        currentUserId: () => 'uid-minh',
        monitor: monitor,
      );
      addTearDown(() async {
        await second.dispose();
        await secondDb.close();
      });
      await repository.start();
      await second.start();

      final arrived = second.watchNotes().firstWhere(
        (notes) => notes.isNotEmpty,
      );
      await repository.createNote(buildNote());
      remote.emitSnapshot();
      await arrived.timeout(const Duration(seconds: 2));

      remote.upsertError = Exception('Thiết bị B mất mạng');
      await second.updateNote(
        buildNote(title: 'Bản B', updatedAt: DateTime(2026, 11, 25, 9)),
      );
      remote.upsertError = null;
      await repository.updateNote(
        buildNote(title: 'Bản A', updatedAt: DateTime(2026, 11, 25, 10)),
      );

      final resolved = second.watchNotes().firstWhere(
        (notes) => notes.single.title == 'Bản A',
      );
      remote.emitSnapshot();
      await resolved.timeout(const Duration(seconds: 2));
      expect((await repository.getNotes()).single.title, 'Bản A');
      expect(remote.archived.map((note) => note.title), contains('Bản B'));
    },
  );

  test('đã đăng xuất thì không đẩy lên máy chủ', () async {
    final SyncedNoteRepository signedOut = SyncedNoteRepository(
      daoForUser: (_) => dao,
      remote: remote,
      currentUserId: () => null,
      monitor: monitor,
    );
    addTearDown(signedOut.dispose);

    await signedOut.createNote(buildNote(title: 'Khách'));
    await signedOut.start();

    expect(remote.pushed, isEmpty);
    expect(monitor.status, SyncStatus.disabled);
  });
}
