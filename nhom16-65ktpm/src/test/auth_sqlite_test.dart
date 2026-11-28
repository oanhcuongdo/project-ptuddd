import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/core/services/auth_service.dart';
import 'package:gooddeeds_fund/data/models/user_model.dart';

void main() {
  group('AuthService & UserModel Unit Tests', () {
    final authService = AuthService.instance;

    setUp(() {
      authService.logout();
    });

    test('Kiểm tra danh sách 4 tài khoản demo đầy đủ thông tin thành viên', () {
      expect(AuthService.demoAccounts.length, 4);

      final huynh = AuthService.demoAccounts.firstWhere((u) => u.studentId == '2351170599');
      expect(huynh.name, 'Nguyễn Văn Huỳnh');
      expect(huynh.role, 'admin');
      expect(huynh.isAdmin, isTrue);
      expect(huynh.password, 'GoodDeeds@2026');

      final latuan = AuthService.demoAccounts.firstWhere((u) => u.studentId == '2151060296');
      expect(latuan.name, 'Lê Anh Tuấn');
      expect(latuan.role, 'member');
      expect(latuan.isAdmin, isFalse);

      final kien = AuthService.demoAccounts.firstWhere((u) => u.studentId == '2251172394');
      expect(kien.name, 'Nguyễn Trung Kiên');
      expect(kien.role, 'member');

      final tatuan = AuthService.demoAccounts.firstWhere((u) => u.studentId == '2351170629');
      expect(tatuan.name, 'Trần Anh Tuấn');
      expect(tatuan.role, 'member');
    });

    test('Đăng nhập thành công với mật khẩu GoodDeeds@2026', () async {
      final success = await authService.login('huynh@gooddeeds.vn', 'GoodDeeds@2026');
      expect(success, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.currentUser?.name, 'Nguyễn Văn Huỳnh');
      expect(authService.isAdmin, isTrue);
    });

    test('Đăng nhập thành công bằng MSSV', () async {
      final success = await authService.login('2151060296', 'GoodDeeds@2026');
      expect(success, isTrue);
      expect(authService.currentUser?.name, 'Lê Anh Tuấn');
      expect(authService.isAdmin, isFalse);
    });

    test('Đăng nhập thất bại khi sai mật khẩu', () async {
      final success = await authService.login('huynh@gooddeeds.vn', 'SaiMatKhau');
      expect(success, isFalse);
      expect(authService.isLoggedIn, isFalse);
    });

    test('Đăng nhập nhanh Quick Login hoạt động chuẩn xác', () {
      final kienAcc = AuthService.demoAccounts.firstWhere((u) => u.studentId == '2251172394');
      authService.quickLogin(kienAcc);

      expect(authService.isLoggedIn, isTrue);
      expect(authService.currentUser?.name, 'Nguyễn Trung Kiên');
      expect(authService.isAdmin, isFalse);

      authService.logout();
      expect(authService.isLoggedIn, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('Chặn mật khẩu yếu 123 và khoá hoàn toàn mật khẩu cũ sau khi đổi', () async {
      // 1. Mật khẩu 123 không được phép đăng nhập
      final weakLogin = await authService.login('2351170599', '123');
      expect(weakLogin, isFalse);

      // 2. Đăng nhập đúng bằng mật khẩu hiện tại
      final currentLogin = await authService.login('2351170599', 'GoodDeeds@2026');
      expect(currentLogin, isTrue);

      // 3. Đổi sang mật khẩu mới
      final changeSuccess = await authService.changePassword('BrandNewPass@2026');
      expect(changeSuccess, isTrue);

      // 4. Đăng xuất
      authService.logout();

      // 5. Đăng nhập lại bằng mật khẩu cũ phải THẤT BẠI
      final oldPassLogin = await authService.login('2351170599', 'GoodDeeds@2026');
      expect(oldPassLogin, isFalse);

      // 6. Đăng nhập bằng mật khẩu 123 phải THẤT BẠI
      final fakePassLogin = await authService.login('2351170599', '123');
      expect(fakePassLogin, isFalse);

      // 7. Chỉ mật khẩu mới đăng nhập THÀNH CÔNG
      final newPassLogin = await authService.login('2351170599', 'BrandNewPass@2026');
      expect(newPassLogin, isTrue);
    });

    test('Đổi mật khẩu thành công và cập nhật phiên hiện tại', () async {
      final successLogin = await authService.login('2351170599', 'GoodDeeds@2026');
      expect(successLogin, isTrue);

      final changeSuccess = await authService.changePassword('NewSecurePass#2026');
      expect(changeSuccess, isTrue);
      expect(authService.currentUser?.password, 'NewSecurePass#2026');
    });

    test('Kiểm tra UserModel serialization toMap và fromMap', () {
      const user = UserModel(
        id: 'usr_test',
        name: 'Test User',
        studentId: '1234567890',
        email: 'test@gooddeeds.vn',
        role: 'admin',
        password: 'Password@123',
      );

      final map = user.toMap();
      expect(map['id'], 'usr_test');
      expect(map['name'], 'Test User');
      expect(map['studentId'], '1234567890');
      expect(map['email'], 'test@gooddeeds.vn');
      expect(map['role'], 'admin');
      expect(map['password'], 'Password@123');

      final reconstructed = UserModel.fromMap(map);
      expect(reconstructed.id, user.id);
      expect(reconstructed.name, user.name);
      expect(reconstructed.studentId, user.studentId);
      expect(reconstructed.role, user.role);
      expect(reconstructed.isAdmin, isTrue);
    });
  });
}
