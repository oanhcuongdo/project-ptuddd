import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buddytalk/app/buddytalk_app.dart';
import 'package:buddytalk/app/layouts/main_layout.dart';
import 'package:buddytalk/app/router/guards/auth_guard.dart';
import 'package:buddytalk/app/router/routes/index.dart';
import 'package:buddytalk/features/auth_profile/data/models/profile_model.dart';
import 'package:buddytalk/features/auth_profile/data/repositories/auth_repository.dart';
import 'package:buddytalk/features/auth_profile/presentation/providers/auth_provider.dart';

class _FakeRestoredAuthRepository extends AuthRepository {
  @override
  bool get canRestoreSession => true;

  @override
  Future<ProfileModel?> restoreSession() async {
    return const ProfileModel(
      userId: 'u-restored',
      displayName: 'Phạm Văn Hưng',
      targetLang: 'en',
      proficiencyLevel: 'B1',
      streakCount: 5,
      dailyGoalMinutes: 20,
    );
  }
}

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
    expect(find.text('Đăng ký nhanh với Google'), findsNothing);

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

  testWidgets('MainLayout hiển thị Sidebar NavLink + Header + Outlet trên Chrome & Mobile', (
    tester,
  ) async {
    // 1. Chrome Desktop (1280x900)
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: MainLayout()),
      ),
    );
    await tester.pumpAndSettle();

    // Kiểm tra Sidebar + Header + Outlet mặc định (Kỷ luật)
    expect(find.text('BuddyTalk'), findsOneWidget);
    expect(find.text('Kỷ luật cá nhân'), findsOneWidget);
    expect(find.text('Chuỗi Kỷ Luật (Streak)'), findsOneWidget);

    // Chuyển NavLink sang "Trò chuyện" -> Header & Outlet cập nhật tương ứng
    await tester.tap(find.text('Trò chuyện'));
    await tester.pumpAndSettle();
    expect(find.text('Trò chuyện Realtime'), findsOneWidget);
    expect(
      find.text('Phân Hệ Chat Realtime (Chat 1-1 & Chat Nhóm Học Tập)'),
      findsOneWidget,
    );

    // Thử thu gọn Sidebar bằng nút << ngang hàng với logo BuddyTalk
    await tester.tap(find.byTooltip('Thu gọn menu'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mở rộng menu'), findsOneWidget);

    // 2. Chuyển sang Mobile (390x900) — đảm bảo không tràn layout
    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('AuthGuard tự động khôi phục phiên đăng nhập sau khi F5', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(repository: _FakeRestoredAuthRepository()),
        child: const MaterialApp(home: AuthGuard(child: MainLayout())),
      ),
    );
    await tester.pumpAndSettle();

    // Không bị đẩy về Login mà vào thẳng MainLayout kèm tên & Streak đã khôi phục
    expect(find.text('BuddyTalk'), findsOneWidget);
    expect(find.text('Phạm Văn Hưng'), findsOneWidget);
    expect(find.text('5 ngày'), findsOneWidget);
  });
}
