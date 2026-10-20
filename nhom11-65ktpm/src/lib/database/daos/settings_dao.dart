import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<AppSetting?> getSetting(String key) {
    return (select(appSettings)..where((tbl) => tbl.settingsPk.equals(key))).getSingleOrNull();
  }

  Future<int> setSetting(String key, String valueJson) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        settingsPk: Value(key),
        settingsJSON: Value(valueJson),
        dateTimeModified: Value(DateTime.now()),
      ),
    );
  }
}
