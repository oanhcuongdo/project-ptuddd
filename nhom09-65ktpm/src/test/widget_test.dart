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
import 'package:buddytalk/features/chat/data/models/conversation_model.dart';
import 'package:buddytalk/features/chat/data/repositories/chat_repository.dart';
import 'package:buddytalk/features/chat/presentation/providers/chat_provider.dart';
import 'package:buddytalk/features/chat/presentation/screens/chat_rooms_tab.dart';

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

class _FakeChatRepository extends ChatRepository {
  bool _joined = false;
  final List<ConversationModel> _createdRooms = [];

  @override
  bool get isReady => true;

  @override
  Future<List<LanguageModel>> fetchAllowedLanguages() async => const [
        LanguageModel(
          code: 'en',
          name: 'English',
          shortLabel: 'Anh',
          flagCode: 'GB',
          sortOrder: 1,
        ),
      ];

  ConversationModel _sampleRoom() => ConversationModel(
        id: 'room-1',
        type: 'group',
        name: 'CLB Luyện Tiếng Anh Giao Tiếp',
        description: 'Thực hành phản xạ giao tiếp 20 phút mỗi tối.',
        level: 'A2',
        targetLang: 'en',
        maxMembers: 20,
        createdBy: 'u-owner',
        managerName: 'Nguyễn Minh Anh',
        memberCount: _joined ? 4 : 3,
        isJoined: _joined,
      );

  @override
  Future<List<ConversationModel>> fetchMyConversations(String userId) async {
    return [
      ..._createdRooms,
      if (_joined) _sampleRoom(),
    ];
  }

  @override
  Future<List<ConversationModel>> fetchPublicGroupRooms({
    required String userId,
    String? searchQuery,
    String? targetLang,
    String? level,
  }) async {
    return [..._createdRooms, _sampleRoom()];
  }

  @override
  Future<ConversationModel> createGroupRoom({
    required String createdBy,
    required String managerName,
    required String name,
    required String description,
    String? level,
    required String targetLang,
    int? maxMembers,
  }) async {
    final created = ConversationModel(
      id: 'room-new-${_createdRooms.length + 1}',
      type: 'group',
      name: name.trim(),
      description: description.trim(),
      level: level,
      targetLang: targetLang,
      maxMembers: maxMembers,
      createdBy: createdBy,
      managerName: managerName,
      memberCount: 1,
      isJoined: true,
      myRole: 'owner',
    );
    _createdRooms.add(created);
    return created;
  }

  @override
  Future<void> joinRoom({
    required String conversationId,
    required String userId,
  }) async {
    _joined = true;
  }

  @override
  Future<void> leaveRoom({
    required String conversationId,
    required String userId,
  }) async {
    _joined = false;
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
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(repository: repo),
          ),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => ChatProvider(repository: _FakeChatRepository()),
          ),
        ],
        child: const MaterialApp(home: AuthGuard(child: MainLayout())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bước 1 / 2'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

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
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(autoRestore: false),
          ),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => ChatProvider(repository: _FakeChatRepository()),
          ),
        ],
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

  testWidgets('ChatRoomsTab: Khám phá danh sách phòng nhóm và bấm Tham gia phòng', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final authRepo = _FakeAuthRepository(
      initialProfile: const ProfileModel(
        userId: 'u-chat',
        displayName: 'Phạm Văn Hưng',
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(repository: authRepo),
          ),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => ChatProvider(repository: _FakeChatRepository()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ChatRoomsTab())),
      ),
    );
    await tester.pumpAndSettle();

    // Chuyển sang tab Khám phá phòng học
    await tester.tap(find.text('Khám phá (1)'));
    await tester.pumpAndSettle();

    expect(find.text('CLB Luyện Tiếng Anh Giao Tiếp'), findsOneWidget);
    expect(find.text('Quản lý: Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Tham gia'), findsOneWidget);
    expect(find.text('Hiển thị 1–1 trong tổng số 1 phòng'), findsOneWidget);

    // Thử chuyển chế độ Danh sách <-> Lưới
    await tester.tap(find.text('Danh sách'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưới'));
    await tester.pumpAndSettle();

    // Bấm Tham gia -> cập nhật sang Vào chat và hiện trong Phòng của tôi (1)
    await tester.tap(find.text('Tham gia'));
    await tester.pumpAndSettle();

    expect(find.text('Phòng của tôi (1)'), findsOneWidget);
    expect(find.text('Vào chat'), findsOneWidget);

    // Mở hộp thoại + Tạo phòng mới (Không yêu cầu trình độ & Không giới hạn thành viên)
    await tester.tap(find.text('Tạo phòng mới'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo phòng học nhóm mới'), findsOneWidget);
    expect(find.text('Người quản lý phòng: Phạm Văn Hưng'), findsOneWidget);
    expect(find.text('Không yêu cầu'), findsOneWidget);
    expect(find.text('Không giới hạn'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Phòng Luyện Nói Tự Do',
    );

    // Chọn ngôn ngữ
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GB English').last);
    await tester.pumpAndSettle();

    // Tạo phòng với mặc định Không yêu cầu trình độ & Không giới hạn thành viên
    await tester.ensureVisible(find.text('Tạo phòng nhóm ngay'));
    await tester.tap(find.text('Tạo phòng nhóm ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Phòng của tôi (2)'), findsOneWidget);
    expect(find.text('Phòng Luyện Nói Tự Do'), findsOneWidget);
    expect(find.text('Mọi trình độ'), findsOneWidget);
    expect(find.text('1 thành viên • Không giới hạn'), findsOneWidget);
    expect(find.text('Quản lý: Phạm Văn Hưng'), findsOneWidget);

    // Bấm Vào chat -> mở giao diện phòng chat bên trong Outlet
    await tester.ensureVisible(find.text('Vào chat').first);
    await tester.tap(find.text('Vào chat').first);
    await tester.pumpAndSettle();

    expect(find.text('Bắt đầu luyện'), findsOneWidget);
    expect(find.byTooltip('Gợi ý chủ đề & câu mở đầu'), findsOneWidget);

    // Thử nhập tin nhắn preview trên giao diện phòng chat rồi quay lại danh sách
    await tester.enterText(
      find.byType(TextField).last,
      'Hello everyone!',
    );
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pumpAndSettle();
    expect(find.text('Hello everyone!'), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại danh sách phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng của tôi (2)'), findsOneWidget);
  });
}
