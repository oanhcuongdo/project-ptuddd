import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/core/theme/app_theme.dart';
import 'package:nhom14_app/screens/home_screen.dart';
import 'package:nhom14_app/screens/module_placeholder_screen.dart';

void main() {
  void setupDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets(
    'HomeScreen renders overview sections, quick access modules, and navigation controls for student',
    (WidgetTester tester) async {
      setupDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(
            title: 'Trang Chủ Kiểm Thử',
            initialProfile: {
              'id': 'test-student-id',
              'full_name': 'Nguyễn Văn A',
              'student_code': '2151060001',
              'class_name': '65KTPM',
              'role': 'student',
            },
          ),
        ),
      );

      // 1. Kiểm tra AppBar và Header
      expect(find.text('Trang Chủ Kiểm Thử'), findsOneWidget);
      expect(find.textContaining('Xin chào'), findsOneWidget);
      expect(
        find.text('Hệ thống hỗ trợ định hướng và chuẩn bị đồ án tốt nghiệp'),
        findsOneWidget,
      );

      // 2. Kiểm tra khu vực tổng quan (các thẻ thống kê với giá trị 0 mặc định)
      expect(find.text('Tổng quan đồ án'), findsOneWidget);
      expect(find.text('Đề tài kho đồ án'), findsOneWidget);
      expect(find.text('Đề tài đã lưu'), findsOneWidget);
      expect(find.text('Tiến độ hoàn thành'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // 3. Kiểm tra khu vực truy cập nhanh gồm 5 module dành cho student
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
      expect(
        find.text('Module đang trong quá trình phát triển'),
        findsOneWidget,
      );

      // 6. Quay lại tab Tổng quan bằng Navigation Sidebar
      await tester.tap(find.text('Tổng quan').first);
      await tester.pumpAndSettle();

      expect(find.text('Tổng quan đồ án'), findsOneWidget);

      // 7. Bấm nút đăng xuất ở Header -> hiển thị Dialog xác nhận
      await tester.tap(find.byIcon(Icons.logout_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
      expect(
        find.text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?',
        ),
        findsOneWidget,
      );
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsWidgets);

      // Bấm 'Hủy' để đóng dialog
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận đăng xuất'), findsNothing);
    },
  );

  testWidgets(
    'Role student displays AI, personal topics, plans, and profile in sidebar',
    (WidgetTester tester) async {
      setupDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(
            initialProfile: {
              'id': 'test-student-id',
              'full_name': 'Sinh Viên A',
              'role': 'student',
            },
          ),
        ),
      );

      expect(find.text('Kho đồ án'), findsWidgets);
      expect(find.text('AI gợi ý'), findsOneWidget);
      expect(find.text('Đề tài cá nhân'), findsWidgets);
      expect(find.text('Kế hoạch'), findsOneWidget);
      expect(find.text('Hồ sơ'), findsOneWidget);
    },
  );

  testWidgets(
    'Role lecturer displays warehouse management and profile, hides student-specific modules',
    (WidgetTester tester) async {
      setupDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(
            initialProfile: {
              'id': 'test-lecturer-id',
              'full_name': 'Giảng Viên B',
              'role': 'lecturer',
            },
          ),
        ),
      );

      // Hiển thị Tổng quan, Kho đồ án, Hồ sơ
      expect(find.text('Tổng quan'), findsWidgets);
      expect(find.text('Kho đồ án'), findsWidgets);
      expect(find.text('Hồ sơ'), findsOneWidget);

      // Ẩn các module riêng của student khỏi sidebar và truy cập nhanh
      expect(find.text('AI gợi ý'), findsNothing);
      expect(find.text('AI gợi ý đề tài'), findsNothing);
      expect(find.text('Đề tài cá nhân'), findsNothing);
      expect(find.text('Kế hoạch'), findsNothing);
      expect(find.text('Kế hoạch & tiến độ'), findsNothing);

      // Kiểm tra truy cập kho đồ án của lecturer
      await tester.tap(find.text('Kho & Quản lý kho'));
      await tester.pumpAndSettle();

      expect(find.text('Kho đồ án & Quản lý kho'), findsWidgets);
      expect(find.text('AI gợi ý & đối chiếu đề tài'), findsNothing);
    },
  );

  testWidgets(
    'Role admin displays warehouse management and profile, hides student-specific modules',
    (WidgetTester tester) async {
      setupDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(
            initialProfile: {
              'id': 'test-admin-id',
              'full_name': 'Quản Trị Viên C',
              'role': 'admin',
            },
          ),
        ),
      );

      // Hiển thị Tổng quan, Kho đồ án, Hồ sơ
      expect(find.text('Tổng quan'), findsWidgets);
      expect(find.text('Kho đồ án'), findsWidgets);
      expect(find.text('Hồ sơ'), findsOneWidget);

      // Ẩn các module riêng của student
      expect(find.text('AI gợi ý'), findsNothing);
      expect(find.text('AI gợi ý đề tài'), findsNothing);
      expect(find.text('Đề tài cá nhân'), findsNothing);
      expect(find.text('Kế hoạch'), findsNothing);
      expect(find.text('Kế hoạch & tiến độ'), findsNothing);
    },
  );

  testWidgets(
    'Undetermined role does not display student-specific or admin modules',
    (WidgetTester tester) async {
      setupDesktopViewport(tester);

      // Khởi tạo không có profile / role chưa xác định
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(initialProfile: null),
        ),
      );

      // Không mặc định student: Chỉ có Tổng quan và Hồ sơ trong navigation
      expect(find.text('Tổng quan'), findsWidgets);
      expect(find.text('Hồ sơ'), findsOneWidget);

      // Không hiển thị module dành riêng cho student
      expect(find.text('AI gợi ý'), findsNothing);
      expect(find.text('AI gợi ý đề tài'), findsNothing);
      expect(find.text('Đề tài cá nhân'), findsNothing);
      expect(find.text('Kế hoạch'), findsNothing);
      expect(find.text('Kế hoạch & tiến độ'), findsNothing);
      expect(find.text('Kho & Quản lý kho'), findsNothing);
      expect(find.text('Kho đồ án'), findsNothing);
    },
  );

  testWidgets('Invalid role only allows access to Overview and Profile', (
    WidgetTester tester,
  ) async {
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(
          initialProfile: {
            'id': 'test-invalid-id',
            'full_name': '',
            'role': 'guest_unknown',
          },
        ),
      ),
    );

    // Xử lý full_name rỗng hiển thị fallback Người dùng
    expect(find.textContaining('Xin chào, Người dùng'), findsOneWidget);

    // Chỉ có Tổng quan và Hồ sơ
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Hồ sơ'), findsOneWidget);
    expect(find.text('Kho đồ án'), findsNothing);
    expect(find.text('AI gợi ý'), findsNothing);
    expect(find.text('AI gợi ý đề tài'), findsNothing);
    expect(find.text('Đề tài cá nhân'), findsNothing);
    expect(find.text('Kế hoạch'), findsNothing);
    expect(find.text('Kế hoạch & tiến độ'), findsNothing);
  });

  testWidgets(
    'Invalid role only allows access to Overview and Profile',
    (WidgetTester tester) async {
      setupDesktopViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(
            initialProfile: {
              'id': 'test-invalid-id',
              'full_name': '',
              'role': 'guest_unknown',
            },
          ),
        ),
      );

      // Xử lý full_name rỗng hiển thị fallback Người dùng
      expect(find.textContaining('Xin chào, Người dùng'), findsOneWidget);

      // Chỉ có Tổng quan và Hồ sơ
      expect(find.text('Tổng quan'), findsWidgets);
      expect(find.text('Hồ sơ'), findsOneWidget);
      expect(find.text('Kho đồ án'), findsNothing);
      expect(find.text('AI gợi ý'), findsNothing);
      expect(find.text('AI gợi ý đề tài'), findsNothing);
      expect(find.text('Đề tài cá nhân'), findsNothing);
      expect(find.text('Kế hoạch'), findsNothing);
      expect(find.text('Kế hoạch & tiến độ'), findsNothing);
    },
  );
}
