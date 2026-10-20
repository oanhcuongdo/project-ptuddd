import 'package:drift/drift.dart';

class AppSettings extends Table {
  TextColumn get settingsPk => text()();
  TextColumn get settingsJSON => text()();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {settingsPk};
}
