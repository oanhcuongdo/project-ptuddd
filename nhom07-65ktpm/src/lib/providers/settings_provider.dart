import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/database_helper.dart';
import '../data/models/reminder_model.dart';
import '../data/models/user_model.dart';
import '../data/services/supabase_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCurrentUserEmail = 'current_user_email';
  static const String _keyPwdPrefix = 'auth_pwd_';
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keySaveAiHistory = 'save_ai_history';

  UserModel _user = UserModel(
    name: 'Mã Khánh Linh',
    email: 'mkl.deeptry@gmail.com',
    studentId: '2351170602',
    className: '65KTPM',
  );
  List<ReminderModel> _reminders = [];
  bool _isDarkMode = true;
  bool _isLoggedIn = false;
  bool _saveAiHistory = true;

  UserModel get user => _user;
  List<ReminderModel> get reminders => _reminders;
  bool get isDarkMode => _isDarkMode;
  bool get isLoggedIn => _isLoggedIn;
  bool get saveAiHistory => _saveAiHistory;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      _isDarkMode = prefs.getBool(_keyDarkMode) ?? true;
      _saveAiHistory = prefs.getBool(_keySaveAiHistory) ?? true;
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
    var foundUser = await DatabaseHelper.instance.getUserByEmail(trimmedEmail);
    String? remotePwd;
    if (foundUser == null) {
      // Thử tìm tài khoản trên Supabase nếu chưa có trong SQLite cục bộ
      foundUser = await SupabaseService.instance.fetchUserByEmail(trimmedEmail);
      if (foundUser != null) {
        await DatabaseHelper.instance.registerUser(foundUser);
      }
    }
    remotePwd = await SupabaseService.instance.fetchUserPassword(trimmedEmail);

    if (foundUser == null) {
      return 'Email chưa được đăng ký trong hệ thống.';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPwd = prefs.getString('$_keyPwdPrefix$trimmedEmail');
      final expectedPwd =
          savedPwd ?? remotePwd ?? (trimmedEmail == 'mkl.deeptry@gmail.com' ? '123456' : '');
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
    final existingLocal = await DatabaseHelper.instance.getUserByEmail(trimmedEmail);
    final existingRemote = await SupabaseService.instance.fetchUserByEmail(trimmedEmail);
    if (existingLocal != null || existingRemote != null) {
      return 'Email này đã được sử dụng. Vui lòng dùng email khác.';
    }

    final newUser = UserModel(
      name: name.trim(),
      email: trimmedEmail,
      studentId: studentId.trim(),
      className: className.trim(),
    );

    await DatabaseHelper.instance.registerUser(newUser);
    await SupabaseService.instance.upsertUser(newUser, password: password);

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

  Future<void> updateProfile({
    required String name,
    required String studentId,
    required String className,
  }) async {
    final updated = UserModel(
      id: _user.id,
      name: name.trim(),
      email: _user.email,
      studentId: studentId.trim(),
      className: className.trim(),
      createdAt: _user.createdAt,
    );
    await DatabaseHelper.instance.updateUser(updated);
    await SupabaseService.instance.updateUserProfile(updated);
    _user = updated;
    notifyListeners();
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

  Future<void> toggleTheme(bool dark) async {
    _isDarkMode = dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkMode, dark);
    } catch (e) {
      debugPrint('[SettingsProvider] Dark mode prefs error: $e');
    }
  }

  Future<void> toggleSaveAiHistory(bool val) async {
    _saveAiHistory = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySaveAiHistory, val);
    } catch (e) {
      debugPrint('[SettingsProvider] Save AI history prefs error: $e');
    }
  }

  Future<void> clearAllPersonalData() async {
    await DatabaseHelper.instance.clearPersonalData();
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
