import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/subjects_table.dart';

part 'subject_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectDao extends DatabaseAccessor<AppDatabase> with _$SubjectDaoMixin {
  SubjectDao(super.db);

  Stream<List<Subject>> watchAllSubjects() {
    return (select(subjects)
          ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<Subject>> getAllSubjects() => select(subjects).get();

  Future<Subject?> getSubjectById(String id) {
    return (select(subjects)..where((tbl) => tbl.subjectPk.equals(id))).getSingleOrNull();
  }

  Future<int> insertSubject(Insertable<Subject> subject) => into(subjects).insert(subject);

  Future<bool> updateSubject(Insertable<Subject> subject) => update(subjects).replace(subject);

  Future<int> deleteSubjectById(String id) {
    return (delete(subjects)..where((tbl) => tbl.subjectPk.equals(id))).go();
  }
}
