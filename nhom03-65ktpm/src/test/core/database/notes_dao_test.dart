import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';

void main() {
  late AppDatabase database;
  late NotesDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = NotesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  NotesCompanion newNote({
    required String id,
    String title = '',
    String content = '',
    String kind = 'note',
    DateTime? updatedAt,
  }) {
    final now = updatedAt ?? DateTime(2026, 11, 21, 10);
    return NotesCompanion.insert(
      id: id,
      title: Value(title),
      content: Value(content),
      kind: Value(kind),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  test('bảng notes tạo được và đọc lại đúng dữ liệu', () async {
    await dao.insertNote(
      newNote(id: 'n1', title: 'Ghi chú 1', content: 'Nội dung 1'),
    );

    final row = await dao.findById('n1');

    expect(row, isNotNull);
    expect(row!.title, 'Ghi chú 1');
    expect(row.content, 'Nội dung 1');
    expect(row.kind, 'note');
    expect(row.deletedAt, isNull);
  });

  test('getAll trả về ghi chú mới cập nhật trước', () async {
    await dao.insertNote(
      newNote(id: 'old', title: 'Cũ', updatedAt: DateTime(2026, 11, 20, 8)),
    );
    await dao.insertNote(
      newNote(id: 'new', title: 'Mới', updatedAt: DateTime(2026, 11, 21, 9)),
    );

    final rows = await dao.getAll();

    expect(rows.map((row) => row.id).toList(), <String>['new', 'old']);
  });

  test('updateNote đổi nội dung và updatedAt', () async {
    await dao.insertNote(newNote(id: 'n1', content: 'trước'));
    final later = DateTime(2026, 11, 21, 15);

    final updated = await dao.updateNote(
      'n1',
      NotesCompanion(
        content: const Value<String>('sau'),
        updatedAt: Value<DateTime>(later),
      ),
    );

    final row = await dao.findById('n1');
    expect(updated, isTrue);
    expect(row!.content, 'sau');
    expect(row.updatedAt, later);
  });

  test(
    'softDeleteNote ẩn ghi chú khỏi danh sách nhưng còn trong bảng',
    () async {
      await dao.insertNote(newNote(id: 'n1'));

      await dao.softDeleteNote('n1');

      expect(await dao.getAll(), isEmpty);
      final row = await dao.findById('n1');
      expect(row, isNotNull);
      expect(row!.deletedAt, isNotNull);
    },
  );

  test('updateNote trả false khi id không tồn tại', () async {
    final updated = await dao.updateNote(
      'khong-ton-tai',
      const NotesCompanion(content: Value<String>('x')),
    );

    expect(updated, isFalse);
  });
}
