import 'package:drift/drift.dart';

class DeleteLogs extends Table {
  TextColumn get deleteLogPk => text()();
  TextColumn get entryPk => text()();
  TextColumn get itemType => text()(); // 'document', 'subject'
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {deleteLogPk};
}
