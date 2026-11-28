import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen validation and interaction tests', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // 1. Hiển thị đúng các thành phần ban đầu
    expect(find.text('HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN'), findsOneWidget);
    expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    // 2. Kiểm tra validate khi để trống trường dữ liệu
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);

    // 3. Kiểm tra validate khi nhập email sai định dạng
    await tester.enterText(find.byType(TextFormField).at(0), 'email_khong_hop_le');
    await tester.enterText(find.byType(TextFormField).at(1), 'matkhau123');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.text('Email không hợp lệ (ví dụ: sinhvien@e.tlu.edu.vn)'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);

    // 4. Kiểm tra bật/tắt ẩn hiện mật khẩu
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });
}
