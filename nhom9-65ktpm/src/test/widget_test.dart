import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buddytalk/app/buddytalk_app.dart';
import 'package:buddytalk/app/router/routes/index.dart';

void main() {
  setUpAll(() {
    registerAllRoutes();
  });

  testWidgets('Luồng Đăng nhập & Đăng ký 2 bước Responsive (Mobile & Chrome)', (
    tester,
  ) async {
    // 1. Mobile (Android)
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const BuddyTalkApp());
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);

    // 2. Chuyển sang Bước 1 / 2 của Đăng ký
    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Bước 1 / 2'), findsOneWidget);
    expect(find.text('Tạo tài khoản BuddyTalk'), findsOneWidget);
    expect(find.text('Độ mạnh mật khẩu'), findsOneWidget);
    expect(find.text('Đăng ký nhanh với Google'), findsOneWidget);

    // Nhập thông tin Bước 1 và bấm sang Bước 2 / 2
    await tester.enterText(find.byType(TextFormField).at(0), 'Phạm Văn Hưng');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'phamvanhung@65ktpm.edu.vn',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Hung@123456');
    await tester.enterText(find.byType(TextFormField).at(3), 'Hung@123456');
    await tester.pump();

    expect(find.text('Mạnh'), findsOneWidget);

    await tester.ensureVisible(find.text('Đăng ký & Thiết lập hồ sơ'));
    await tester.tap(find.text('Đăng ký & Thiết lập hồ sơ'));
    await tester.pumpAndSettle();

    // 3. Xác nhận Bước 2 / 2 hiển thị đầy đủ trên Mobile
    expect(find.text('Bước 2 / 2'), findsOneWidget);
    expect(find.text('Thiết lập hồ sơ & Kỷ luật'), findsOneWidget);
    expect(find.text('Cú Thông Thái'), findsOneWidget);
    expect(find.text('20 phút'), findsOneWidget);

    // 4. Xác nhận Bước 2 / 2 hiển thị 2 cột kiểu Facebook trên Chrome Desktop
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.text('Thiết lập hồ sơ & Kỷ luật'), findsOneWidget);
    expect(
      find.text('Duy trì chuỗi kỷ luật (Streak) và Ma trận nhiệt mỗi ngày'),
      findsOneWidget,
    );
  });
}
