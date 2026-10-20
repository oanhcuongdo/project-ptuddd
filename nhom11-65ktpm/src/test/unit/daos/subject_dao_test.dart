import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:study_material_manager/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Tầng Data Layer - SubjectDao Tests', () {
    test('CRUD môn học và sắp xếp theo tên A-Z', () async {
      final now = DateTime.now();

      await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(
          subjectPk: 's-toan',
          code: 'MATH101',
          name: 'Toán Rời rạc',
          dateTimeModified: now,
        ),
      );

      await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(
          subjectPk: 's-ktpm',
          code: 'SE310',
          name: 'Kiến trúc Phần mềm',
          dateTimeModified: now,
        ),
      );

      final subjects = await db.subjectDao.getAllSubjects();
      expect(subjects.length, equals(2));

      // SubjectDao watchAllSubjects sắp xếp asc theo tên
      final sortedStream = await db.subjectDao.watchAllSubjects().first;
      expect(sortedStream.first.name, equals('Kiến trúc Phần mềm'));
      expect(sortedStream.last.name, equals('Toán Rời rạc'));
    });
  });
}
