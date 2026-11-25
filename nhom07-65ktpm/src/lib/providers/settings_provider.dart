import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/database_helper.dart';
import '../data/models/reminder_model.dart';
import '../data/models/user_model.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCurrentUserEmail = 'current_user_email';
  static const String _keyPwdPrefix = 'auth_pwd_';

  UserModel _user = UserModel(
    name: 'Mã Khánh Linh',
    email: 'mkl.deeptry@gmail.com',
    studentId: '2351170602',
    className: '65KTPM',
  );
  List<ReminderModel> _reminders = [];
  bool _isDarkMode = true;
  bool _isLoggedIn = false;

  UserModel get user => _user;
  List<ReminderModel> get reminders => _reminders;
  bool get isDarkMode => _isDarkMode;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final savedEmail = prefs.getString(_keyCurrentUserEmail);
      if (_isLoggedIn && savedEmail != null && savedEmail.isNotEmpty) {
        final dbUser = await DatabaseHelper.instance.getUserByEmail(savedEmail);
        if (dbUser != null) {
          _user = dbUser;
        }
      }
    } catch (e) {
      debugPrint('[SettingsProvider] Prefs fallback: $e');
    }
    _reminders = await DatabaseHelper.instance.getReminders();
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();
    final foundUser = await DatabaseHelper.instance.getUserByEmail(trimmedEmail);
    if (foundUser == null) {
      return 'Email chưa được đăng ký trong hệ thống.';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPwd = prefs.getString('$_keyPwdPrefix$trimmedEmail');
      // Default seeded account password fallback is '123456'
      final expectedPwd = savedPwd ?? (trimmedEmail == 'mkl.deeptry@gmail.com' ? '123456' : '');
      if (expectedPwd.isNotEmpty && password != expectedPwd) {
        return 'Mật khẩu không chính xác.';
      }
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyCurrentUserEmail, foundUser.email);
    } catch (e) {
      debugPrint('[SettingsProvider] Login prefs error: $e');
    }

    _user = foundUser;
    _isLoggedIn = true;
    notifyListeners();
    return null;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String studentId,
    required String className,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final existingUser = await DatabaseHelper.instance.getUserByEmail(trimmedEmail);
    if (existingUser != null) {
      return 'Email này đã được sử dụng. Vui lòng dùng email khác.';
    }

    final newUser = UserModel(
      name: name.trim(),
      email: trimmedEmail,
      studentId: studentId.trim(),
      className: className.trim(),
    );

    await DatabaseHelper.instance.registerUser(newUser);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPwdPrefix$trimmedEmail', password);
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyCurrentUserEmail, newUser.email);
    } catch (e) {
      debugPrint('[SettingsProvider] Register prefs error: $e');
    }

    _user = newUser;
    _isLoggedIn = true;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
    } catch (e) {
      debugPrint('[SettingsProvider] Logout prefs error: $e');
    }
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> toggleReminder(ReminderModel reminder, bool val) async {
    final updated = ReminderModel(
      id: reminder.id,
      title: reminder.title,
      hour: reminder.hour,
      minute: reminder.minute,
      type: reminder.type,
      isEnabled: val,
    );
    await DatabaseHelper.instance.updateReminder(updated);
    await loadSettings();
  }

  void toggleTheme(bool dark) {
    _isDarkMode = dark;
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
