import 'package:drift/drift.dart';

class Subjects extends Table {
  TextColumn get subjectPk => text()();
  TextColumn get code => text().withLength(min: 1, max: 30)();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get lecturer => text().nullable()();
  TextColumn get semester => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#1E88E5'))();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {subjectPk};
}
