import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/core/di/note_classification_adapter.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/notes/data/repositories/note_repository_impl.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/subjects/domain/entities/classified_note.dart';

void main() {
  late AppDatabase database;
  late NoteRepositoryImpl notes;
  late NoteClassificationAdapter adapter;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    notes = NoteRepositoryImpl(NotesDao(database));
    adapter = NoteClassificationAdapter(notes);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> addNote(
    String id, {
    String? subjectId,
    List<String> tags = const <String>[],
  }) {
    final time = DateTime(2026, 11, 20);
    return notes.createNote(
      Note(
        id: id,
        title: id,
        content: 'Nội dung $id',
        kind: NoteKind.note,
        createdAt: time,
        updatedAt: time,
        subjectId: subjectId,
        tags: tags,
      ),
    );
  }

  Future<Note> noteById(String id) async => (await notes.findById(id))!;

  test('watchNotes trả môn và tag của từng ghi chú', () async {
    await addNote('n1', subjectId: 'toan', tags: <String>['ôn thi']);

    final classified = await adapter.watchNotes().first;

    expect(
      classified.single,
      const ClassifiedNote(
        id: 'n1',
        title: 'n1',
        subjectId: 'toan',
        tags: <String>['ôn thi'],
      ),
    );
  });

  test('gán rồi bỏ gán môn, tag; giữ nguyên nội dung ghi chú', () async {
    await addNote('n1');

    await adapter.classifyNote(
      'n1',
      subjectId: 'toan',
      tags: <String>['ôn thi', 'bài tập'],
    );
    var note = await noteById('n1');
    expect(note.subjectId, 'toan');
    expect(note.tags, <String>['ôn thi', 'bài tập']);
    expect(note.content, 'Nội dung n1');

    await adapter.classifyNote('n1', subjectId: null, tags: <String>[]);
    note = await noteById('n1');
    expect(note.subjectId, isNull);
    expect(note.tags, isEmpty);
  });

  test('phân loại ghi chú không tồn tại báo lỗi', () async {
    expect(
      () => adapter.classifyNote('khong-co', subjectId: null, tags: <String>[]),
      throwsA(isA<DatabaseFailure>()),
    );
  });

  test('đổi tên tag trên mọi ghi chú và gộp tag trùng', () async {
    await addNote('n1', tags: <String>['on thi', 'bài tập']);
    await addNote('n2', tags: <String>['on thi', 'ôn thi']);
    await addNote('n3', tags: <String>['khác']);

    await adapter.renameTag('on thi', 'ôn thi');

    expect((await noteById('n1')).tags, <String>['ôn thi', 'bài tập']);
    expect((await noteById('n2')).tags, <String>['ôn thi']);
    expect((await noteById('n3')).tags, <String>['khác']);
  });

  test('xoá tag khỏi mọi ghi chú', () async {
    await addNote('n1', tags: <String>['ôn thi', 'bài tập']);
    await addNote('n2', tags: <String>['ôn thi']);

    await adapter.deleteTag('ôn thi');

    expect((await noteById('n1')).tags, <String>['bài tập']);
    expect((await noteById('n2')).tags, isEmpty);
  });

  test('gỡ môn khỏi mọi ghi chú của môn đó', () async {
    await addNote('n1', subjectId: 'toan', tags: <String>['a']);
    await addNote('n2', subjectId: 'van');

    await adapter.clearSubject('toan');

    expect((await noteById('n1')).subjectId, isNull);
    expect((await noteById('n1')).tags, <String>['a']);
    expect((await noteById('n2')).subjectId, 'van');
  });
}
