import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/core/theme/app_theme.dart';
import 'package:nhom14_app/screens/login_screen.dart';
import 'package:nhom14_app/screens/register_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );
  }

  void setupScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('RegisterScreen renders all 4 input fields and submit button', (WidgetTester tester) async {
    setupScreenSize(tester);
    await tester.pumpWidget(createTestWidget(const RegisterScreen()));

    // 1. Kiểm tra tiêu đề và thông tin
    expect(find.text('Tạo Tài Khoản Mới'), findsOneWidget);
    expect(find.text('HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN'), findsOneWidget);

    // 2. Kiểm tra đủ 4 trường nhập liệu
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Họ và tên *'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Mật khẩu *'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu *'), findsOneWidget);

    // 3. Nút đăng ký và liên kết quay lại đăng nhập
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Đăng nhập ngay'), findsOneWidget);
  });

  testWidgets('RegisterScreen validation fails when fields are empty', (WidgetTester tester) async {
    setupScreenSize(tester);
    await tester.pumpWidget(createTestWidget(const RegisterScreen()));

    final registerBtn = find.text('Đăng ký tài khoản');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(find.text('Vui lòng xác nhận mật khẩu'), findsOneWidget);
  });

  testWidgets('RegisterScreen validates invalid email and short password', (WidgetTester tester) async {
    setupScreenSize(tester);
    await tester.pumpWidget(createTestWidget(const RegisterScreen()));

    final fields = find.byType(TextFormField);

    // Điền họ tên hợp lệ
    await tester.enterText(fields.at(0), 'Nguyễn Văn A');
    // Điền email không hợp lệ
    await tester.enterText(fields.at(1), 'email-sai-dinh-dang');
    // Điền mật khẩu ngắn (< 6 ký tự)
    await tester.enterText(fields.at(2), '123');
    // Điền xác nhận mật khẩu không khớp
    await tester.enterText(fields.at(3), '123456');

    final registerBtn = find.text('Đăng ký tài khoản');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pump();

    expect(find.text('Email không hợp lệ (ví dụ: sinhvien@e.tlu.edu.vn)'), findsOneWidget);
    expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
    expect(find.text('Mật khẩu xác nhận không trùng khớp'), findsOneWidget);
  });

  testWidgets('RegisterScreen validates password confirmation match', (WidgetTester tester) async {
    setupScreenSize(tester);
    await tester.pumpWidget(createTestWidget(const RegisterScreen()));

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Nguyễn Văn A');
    await tester.enterText(fields.at(1), 'sinhvien@e.tlu.edu.vn');
    await tester.enterText(fields.at(2), 'matkhau123');
    await tester.enterText(fields.at(3), 'matkhau123');

    final registerBtn = find.text('Đăng ký tài khoản');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pump();

    // Không còn bất kỳ lỗi xác thực cục bộ nào
    expect(find.text('Vui lòng nhập họ và tên'), findsNothing);
    expect(find.text('Vui lòng nhập địa chỉ email'), findsNothing);
    expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
    expect(find.text('Mật khẩu xác nhận không trùng khớp'), findsNothing);
  });

  testWidgets('Navigation from LoginScreen to RegisterScreen works', (WidgetTester tester) async {
    setupScreenSize(tester);
    await tester.pumpWidget(createTestWidget(const LoginScreen()));

    expect(find.text('Chưa có tài khoản? '), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);

    final goToRegisterBtn = find.text('Đăng ký ngay');
    await tester.ensureVisible(goToRegisterBtn);
    await tester.tap(goToRegisterBtn);
    await tester.pumpAndSettle();

    // Màn hình Đăng ký xuất hiện
    expect(find.text('Tạo Tài Khoản Mới'), findsOneWidget);
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);

    final backToLoginBtn = find.text('Đăng nhập ngay');
    await tester.ensureVisible(backToLoginBtn);
    await tester.tap(backToLoginBtn);
    await tester.pumpAndSettle();

    // Quay lại màn hình Đăng nhập
    expect(find.text('HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN'), findsOneWidget);
    expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
  });
}
