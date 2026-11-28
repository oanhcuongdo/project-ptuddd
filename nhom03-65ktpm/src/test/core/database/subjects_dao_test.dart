import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/subjects_dao.dart';

void main() {
  late AppDatabase database;
  late SubjectsDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = SubjectsDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  SubjectsCompanion newSubject(String id, String name, DateTime createdAt) {
    return SubjectsCompanion.insert(
      id: id,
      name: name,
      color: const Value('#2F6BFF'),
      createdAt: Value(createdAt),
      updatedAt: Value(createdAt),
    );
  }

  test('thêm và đọc lại môn học theo thứ tự tạo', () async {
    await dao.insertSubject(newSubject('s2', 'Ngữ văn', DateTime(2026, 11, 2)));
    await dao.insertSubject(newSubject('s1', 'Toán', DateTime(2026, 11, 1)));

    final rows = await dao.watchAll().first;

    expect(rows.map((SubjectRow r) => r.name), <String>['Toán', 'Ngữ văn']);
    expect(rows.first.color, '#2F6BFF');
  });

  test('môn đã xoá mềm không hiện nhưng vẫn còn để đồng bộ', () async {
    await dao.insertSubject(newSubject('s1', 'Toán', DateTime(2026, 11, 1)));

    final updated = await dao.updateSubject(
      's1',
      SubjectsCompanion(deletedAt: Value(DateTime(2026, 11, 3))),
    );

    expect(updated, isTrue);
    expect(await dao.watchAll().first, isEmpty);
    expect((await dao.getAllIncludingDeleted()).single.deletedAt, isNotNull);
  });

  test('upsert ghi đè môn đã có và thêm môn mới', () async {
    await dao.insertSubject(newSubject('s1', 'Toan', DateTime(2026, 11, 1)));

    await dao.upsertSubject(newSubject('s1', 'Toán', DateTime(2026, 11, 1)));
    await dao.upsertSubject(newSubject('s2', 'Lý', DateTime(2026, 11, 2)));

    final rows = await dao.getAllIncludingDeleted();
    expect(
      rows.map((SubjectRow r) => r.name),
      containsAll(<String>['Toán', 'Lý']),
    );
    expect(rows, hasLength(2));
  });

  test('sửa môn không tồn tại trả về false', () async {
    expect(
      await dao.updateSubject('khong-co', const SubjectsCompanion()),
      isFalse,
    );
  });

  test('watchAll phát lại danh sách khi có môn mới', () async {
    final counts = dao
        .watchAll()
        .map((List<SubjectRow> rows) => rows.length)
        .asBroadcastStream();
    // Chờ lần phát đầu tiên (bảng rỗng) rồi mới thêm môn.
    expect(await counts.first, 0);

    final next = counts.first;
    await dao.insertSubject(newSubject('s1', 'Toán', DateTime(2026, 11, 1)));

    expect(await next, 1);
  });
}
