import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:buddytalk/app/buddytalk_app.dart';
import 'package:buddytalk/app/layouts/main_layout.dart';
import 'package:buddytalk/app/router/guards/auth_guard.dart';
import 'package:buddytalk/app/router/routes/index.dart';
import 'package:buddytalk/features/auth_profile/data/models/language_model.dart';
import 'package:buddytalk/features/auth_profile/data/models/profile_model.dart';
import 'package:buddytalk/features/auth_profile/data/repositories/auth_repository.dart';
import 'package:buddytalk/features/auth_profile/presentation/providers/auth_provider.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required this.initialProfile});

  final ProfileModel initialProfile;

  @override
  bool get canRestoreSession => true;

  @override
  Future<ProfileModel?> restoreSession() async => initialProfile;

  @override
  Future<List<LanguageModel>> fetchAllowedLanguages() async => const [
        LanguageModel(
          code: 'vi',
          name: 'Tiếng Việt',
          shortLabel: 'Việt',
          flagCode: 'VN',
          sortOrder: 1,
        ),
        LanguageModel(
          code: 'en',
          name: 'English',
          shortLabel: 'Anh',
          flagCode: 'GB',
          sortOrder: 2,
        ),
        LanguageModel(
          code: 'ja',
          name: 'Tiếng Nhật',
          shortLabel: 'Nhật',
          flagCode: 'JP',
          sortOrder: 3,
        ),
      ];

  @override
  Future<ProfileModel> completeOnboarding({
    required String userId,
    required String displayName,
    String? avatarUrl,
    String? nativeLang,
    required String targetLang,
    required String proficiencyLevel,
    required int dailyGoalMinutes,
  }) async {
    return ProfileModel(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      nativeLang: nativeLang ?? initialProfile.nativeLang,
      targetLang: targetLang,
      proficiencyLevel: proficiencyLevel,
      dailyGoalMinutes: dailyGoalMinutes,
      onboardingCompleted: true,
    );
  }
}

void main() {
  setUpAll(() {
    registerAllRoutes();
  });

  testWidgets('Đăng nhập & Đăng ký gọn nhẹ (chỉ Email, Mật khẩu, Xác nhận MK)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const BuddyTalkApp());
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);

    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản BuddyTalk'), findsOneWidget);
    expect(find.text('Độ mạnh mật khẩu'), findsOneWidget);
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Họ và tên'), findsNothing);
    expect(find.text('Đăng ký nhanh với Google'), findsNothing);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'phamvanhung@65ktpm.edu.vn',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Hung@123456');
    await tester.enterText(find.byType(TextFormField).at(2), 'Hung@123456');
    await tester.pump();

    expect(find.text('Mạnh'), findsOneWidget);
  });

  testWidgets('Onboarding: Bỏ qua Bước 1 tạo tên user_<id> + sang Bước 2 chọn ngôn ngữ & phút tùy chỉnh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _FakeAuthRepository(
      initialProfile: const ProfileModel(
        userId: '1d17ee6a-0895-405d-8d74-fd3000000000',
        displayName: '',
        onboardingCompleted: false,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(repository: repo),
        child: const MaterialApp(home: AuthGuard(child: MainLayout())),
      ),
    );
    await tester.pumpAndSettle();

    // Bước 1 / 2 có nút "Bỏ qua"
    expect(find.text('Bước 1 / 2'), findsOneWidget);
    expect(find.text('Thiết lập hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);

    // Bấm "Bỏ qua" ở Bước 1 -> KHÔNG thoát ra MainLayout mà sang Bước 2 / 2
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

    // Bước 2 / 2: không còn hỏi Ngôn ngữ mẹ đẻ, chỉ chọn ngôn ngữ muốn luyện + trình độ + mục tiêu Duolingo
    expect(find.text('Bước 2 / 2'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsNothing);
    expect(find.text('Ngôn ngữ mẹ đẻ'), findsNothing);
    expect(find.text('JP Nhật'), findsOneWidget);
    expect(find.text('15 phút / ngày'), findsOneWidget);
    expect(find.text('Tùy chỉnh thời gian'), findsOneWidget);

    await tester.tap(find.text('JP Nhật'));
    await tester.tap(find.text('B1'));
    await tester.ensureVisible(find.text('Tùy chỉnh thời gian'));
    await tester.tap(find.text('Tùy chỉnh thời gian'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '45');
    await tester.pump();

    // Hoàn tất Bước 2 -> vào MainLayout với tên mặc định user_1d17ee6a và 45 phút/ngày
    await tester.ensureVisible(find.text('Hoàn tất & Bắt đầu hành trình 🎉'));
    await tester.tap(find.text('Hoàn tất & Bắt đầu hành trình 🎉'));
    await tester.pumpAndSettle();

    expect(find.text('BuddyTalk'), findsOneWidget);
    expect(find.text('user_1d17ee6a'), findsOneWidget);
    expect(find.text('JA • B1'), findsOneWidget);
  });

  testWidgets('MainLayout hiển thị Sidebar NavLink + Header + Outlet trên Chrome & Mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(autoRestore: false),
        child: const MaterialApp(home: MainLayout()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BuddyTalk'), findsOneWidget);
    expect(find.text('Kỷ luật cá nhân'), findsOneWidget);

    await tester.tap(find.text('Trò chuyện'));
    await tester.pumpAndSettle();
    expect(find.text('Trò chuyện Realtime'), findsOneWidget);

    await tester.tap(find.byTooltip('Thu gọn menu'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mở rộng menu'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('AuthGuard tự động vào thẳng MainLayout khi đã hoàn tất Onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _FakeAuthRepository(
      initialProfile: const ProfileModel(
        userId: 'u-restored',
        displayName: 'Phạm Văn Hưng',
        targetLang: 'en',
        proficiencyLevel: 'B1',
        streakCount: 5,
        dailyGoalMinutes: 20,
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(repository: repo),
        child: const MaterialApp(home: AuthGuard(child: MainLayout())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BuddyTalk'), findsOneWidget);
    expect(find.text('Phạm Văn Hưng'), findsOneWidget);
    expect(find.text('5 ngày'), findsOneWidget);
  });
}
