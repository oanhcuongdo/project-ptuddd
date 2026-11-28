import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/core/theme/app_theme.dart';
import 'package:nhom14_app/main.dart';

void main() {
  testWidgets('MyHomePage renders logout controls and shows confirmation dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MyHomePage(title: 'Trang Chủ Kiểm Thử'),
      ),
    );

    // 1. Kiểm tra AppBar có tiêu đề và nút đăng xuất
    expect(find.text('Trang Chủ Kiểm Thử'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsNWidgets(2)); // 1 ở AppBar, 1 ở thẻ Body
    expect(find.text('Đăng xuất tài khoản'), findsOneWidget);

    // 2. Bấm nút đăng xuất ở Body -> Hộp thoại xác nhận xuất hiện
    await tester.tap(find.text('Đăng xuất tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
    expect(find.text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);

    // 3. Bấm 'Hủy' -> Hộp thoại đóng lại
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận đăng xuất'), findsNothing);
  });
}
