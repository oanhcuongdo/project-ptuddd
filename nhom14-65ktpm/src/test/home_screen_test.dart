import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/core/theme/app_theme.dart';
import 'package:nhom14_app/screens/home_screen.dart';
import 'package:nhom14_app/screens/module_placeholder_screen.dart';

void main() {
  testWidgets('HomeScreen renders overview sections, quick access modules, and navigation controls', (WidgetTester tester) async {
    // Đặt kích thước màn hình test để giả lập Desktop Windows
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(title: 'Trang Chủ Kiểm Thử'),
      ),
    );

    // 1. Kiểm tra AppBar và Header
    expect(find.text('Trang Chủ Kiểm Thử'), findsOneWidget);
    expect(find.textContaining('Xin chào'), findsOneWidget);
    expect(find.text('Hệ thống hỗ trợ định hướng và chuẩn bị đồ án tốt nghiệp'), findsOneWidget);

    // 2. Kiểm tra khu vực tổng quan (các thẻ thống kê với giá trị 0 mặc định)
    expect(find.text('Tổng quan đồ án'), findsOneWidget);
    expect(find.text('Đề tài kho đồ án'), findsOneWidget);
    expect(find.text('Đề tài đã lưu'), findsOneWidget);
    expect(find.text('Tiến độ hoàn thành'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // 3. Kiểm tra khu vực truy cập nhanh gồm 5 module
    expect(find.text('Truy cập nhanh'), findsOneWidget);
    expect(find.text('Kho đồ án'), findsWidgets);
    expect(find.text('AI gợi ý đề tài'), findsOneWidget);
    expect(find.text('Đề tài cá nhân'), findsWidgets);
    expect(find.text('Kế hoạch & tiến độ'), findsOneWidget);
    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);

    // 4. Kiểm tra khu vực hoạt động gần đây (trạng thái trống)
    expect(find.text('Hoạt động gần đây'), findsOneWidget);
    expect(find.text('Chưa có hoạt động nào gần đây'), findsOneWidget);

    // 5. Kiểm tra điều hướng: Bấm vào module 'AI gợi ý đề tài'
    await tester.tap(find.text('AI gợi ý đề tài'));
    await tester.pumpAndSettle();

    // Màn hình placeholder tương ứng xuất hiện với thông tin TV phụ trách
    expect(find.byType(ModulePlaceholderScreen), findsOneWidget);
    expect(find.text('AI gợi ý & đối chiếu đề tài'), findsWidgets);
    expect(find.text('Phụ trách: TV3 – Trần Đức Trung'), findsOneWidget);
    expect(find.text('Module đang trong quá trình phát triển'), findsOneWidget);

    // 6. Quay lại tab Tổng quan bằng NavigationRail
    await tester.tap(find.text('Tổng quan').first);
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan đồ án'), findsOneWidget);

    // 7. Bấm nút đăng xuất ở AppBar -> hiển thị Dialog xác nhận
    await tester.tap(find.byIcon(Icons.logout_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
    expect(find.text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsWidgets);

    // Bấm 'Hủy' để đóng dialog
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận đăng xuất'), findsNothing);
  });
}
