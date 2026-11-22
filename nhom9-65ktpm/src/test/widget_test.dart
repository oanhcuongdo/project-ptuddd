import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buddytalk/app/buddytalk_app.dart';
import 'package:buddytalk/app/router/routes/index.dart';

void main() {
  setUpAll(() {
    registerAllRoutes();
  });

  testWidgets('LoginScreen Responsive: Mobile 1 cột & Chrome 2 cột kiểu Facebook', (
    tester,
  ) async {
    // 1. Mobile (Android): 1 cột gọn đẹp
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const BuddyTalkApp());
    await tester.pumpAndSettle();

    final loginBtnFinder = find.text('Đăng nhập');
    final googleBtnFinder = find.text('Tiếp tục với Google');

    expect(loginBtnFinder, findsOneWidget);
    expect(googleBtnFinder, findsOneWidget);
    // Đảm bảo nút Đăng nhập nằm phía TRÊN nút Google
    expect(
      tester.getTopLeft(loginBtnFinder).dy <
          tester.getTopLeft(googleBtnFinder).dy,
      isTrue,
    );

    // 2. Desktop/Chrome: 2 cột kiểu Facebook (Hero bên trái + Card Form bên phải)
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập vào BuddyTalk'), findsOneWidget);
    expect(
      find.text('Duy trì chuỗi kỷ luật (Streak) và Ma trận nhiệt mỗi ngày'),
      findsOneWidget,
    );

    // 3. Chuyển sang màn hình Đăng ký
    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
  });
}
