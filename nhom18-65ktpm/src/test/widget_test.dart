import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/core/theme.dart';
import 'package:ketnoitinhnguyenvienxemay/core/widgets/animated_moto_logo.dart';
import 'package:ketnoitinhnguyenvienxemay/core/widgets/auth_backdrop.dart';
import 'package:ketnoitinhnguyenvienxemay/features/auth/screens/login_screen.dart';
import 'package:ketnoitinhnguyenvienxemay/features/auth/screens/register_screen.dart';

void main() {
  testWidgets('LoginScreen hiển thị nền minh họa, logo xe máy động và báo lỗi khi bỏ trống', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const LoginScreen()),
    );

    expect(find.byType(AuthBackdrop), findsOneWidget);
    expect(find.byType(AnimatedMotoLogo), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);

    // Chạy hết hiệu ứng xe máy chạy vào logo và chạm để phát lại
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AnimatedMotoLogo));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('RegisterScreen có nền chuyển sắc, chọn vai trò trực quan và không cho chọn admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const RegisterScreen()),
    );

    expect(find.byType(AuthBackdrop), findsOneWidget);
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Khách hàng'), findsOneWidget);
    expect(find.text('Chủ tiệm'), findsOneWidget);
    expect(find.text('Tình nguyện'), findsOneWidget);
    expect(find.text('Quản trị viên'), findsNothing);

    // Chuyển vai trò bằng thẻ trực quan
    await tester.tap(find.text('Tình nguyện'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Bật sẵn sàng cứu hộ cộng đồng'),
      findsOneWidget,
    );

    await tester.tap(find.text('Đăng ký'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
  });
}
