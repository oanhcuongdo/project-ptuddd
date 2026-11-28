import 'package:flutter/foundation.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/user_model.dart';

/// Dịch vụ Xác thực & Quản lý Phiên đăng nhập (Authentication Service)
/// Lưu trữ và truy vấn tài khoản trực tiếp từ CSDL SQLite
/// Phụ trách: Nguyễn Văn Huỳnh (Nhóm trưởng)
class AuthService extends ChangeNotifier {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Danh sách 4 tài khoản của 4 thành viên nhóm (Seed Demo Accounts)
  static const List<UserModel> demoAccounts = [
    UserModel(
      id: 'usr_01',
      name: 'Nguyễn Văn Huỳnh',
      studentId: '2351170599',
      email: 'huynh@gooddeeds.vn',
      role: 'admin',
      password: 'GoodDeeds@2026',
    ),
    UserModel(
      id: 'usr_02',
      name: 'Lê Anh Tuấn',
      studentId: '2151060296',
      email: 'latuan@gooddeeds.vn',
      role: 'member',
      password: 'GoodDeeds@2026',
    ),
    UserModel(
      id: 'usr_03',
      name: 'Nguyễn Trung Kiên',
      studentId: '2251172394',
      email: 'kien@gooddeeds.vn',
      role: 'member',
      password: 'GoodDeeds@2026',
    ),
    UserModel(
      id: 'usr_04',
      name: 'Trần Anh Tuấn',
      studentId: '2351170629',
      email: 'tatuan@gooddeeds.vn',
      role: 'member',
      password: 'GoodDeeds@2026',
    ),
  ];

  /// Đăng nhập bằng email/MSSV và mật khẩu (Truy vấn CSDL SQLite thật)
  Future<bool> login(String input, String password) async {
    final cleanInput = input.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Thử xác thực trực tiếp từ CSDL SQLite
    try {
      final dbUser = await DatabaseHelper.instance.authenticateUser(cleanInput, cleanPassword);
      if (dbUser != null) {
        _currentUser = dbUser;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Lỗi truy vấn SQLite (dùng fallback demoAccounts): $e');
    }

    // 2. Fallback an toàn cho môi trường Unit Test hoặc khi SQLite chưa khởi tạo
    for (final acc in demoAccounts) {
      if ((acc.email.toLowerCase() == cleanInput ||
              acc.studentId == cleanInput ||
              acc.name.toLowerCase().contains(cleanInput)) &&
          acc.password == cleanPassword) {
        _currentUser = acc;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Đổi mật khẩu người dùng hiện tại và cập nhật thẳng vào CSDL SQLite
  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;
    final cleanPass = newPassword.trim();
    if (cleanPass.isEmpty) return false;

    try {
      final rows = await DatabaseHelper.instance.updateUserPassword(_currentUser!.id, cleanPass);
      if (rows > 0) {
        _currentUser = _currentUser!.copyWith(password: cleanPass);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Lỗi cập nhật mật khẩu SQLite: $e');
    }

    _currentUser = _currentUser!.copyWith(password: cleanPass);
    notifyListeners();
    return true;
  }

  /// Đăng nhập nhanh 1-chạm (Quick Login Demo cho nhóm 16)
  void quickLogin(UserModel account) {
    _currentUser = account;
    notifyListeners();
  }

  /// Đăng xuất phiên làm việc
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
