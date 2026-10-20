import 'package:drift/drift.dart';
import 'subjects_table.dart';

class Documents extends Table {
  TextColumn get documentPk => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get subjectFk => text().nullable().references(Subjects, #subjectPk)();
  TextColumn get docType => text().withDefault(const Constant('lecture'))(); // 'lecture', 'assignment', 'reference'
  TextColumn get content => text().nullable()(); // Notes, summary, or description
  TextColumn get fileUrl => text().nullable()(); // Path or link
  IntColumn get priority => integer().withDefault(const Constant(1))(); // 0: low, 1: medium, 2: high
  TextColumn get status => text().withDefault(const Constant('active'))(); // 'active', 'completed', 'review'
  DateTimeColumn get dateTimeCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {documentPk};
}
