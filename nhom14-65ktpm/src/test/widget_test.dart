import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/main.dart';

void main() {
  testWidgets('App renders LoginScreen by default after initial session check', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Trong khung hình đầu tiên, hiển thị SplashLoadingView
    expect(find.text('HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN'), findsOneWidget);
    expect(find.text('Đang kiểm tra phiên đăng nhập...'), findsOneWidget);

    // Chờ quá trình kiểm tra phiên ban đầu hoàn thành
    await tester.pumpAndSettle();

    // Chưa đăng nhập -> tự động chuyển sang LoginScreen
    expect(find.text('HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
