import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeController extends ChangeNotifier {
  ThemeModeController._(this._preferences, this._themeMode);

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeModeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);
    final themeMode = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return ThemeModeController._(preferences, themeMode);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (themeMode == _themeMode) return;

    final saved = await _preferences.setString(_themeModeKey, themeMode.name);
    if (!saved) {
      throw StateError('Không thể lưu chế độ giao diện đã chọn.');
    }

    _themeMode = themeMode;
    notifyListeners();
  }
}
