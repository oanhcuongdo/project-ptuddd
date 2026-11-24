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
import 'package:buddytalk/features/chat/data/models/message_model.dart';
import 'package:buddytalk/features/chat/data/models/room_join_request.dart';
import 'package:buddytalk/features/chat/data/repositories/chat_repository.dart';
import 'package:buddytalk/features/chat/presentation/providers/chat_provider.dart';
import 'package:buddytalk/features/chat/presentation/screens/chat_rooms_tab.dart';
import 'package:buddytalk/features/notifications/data/models/notification_model.dart';
import 'package:buddytalk/features/notifications/data/repositories/notification_repository.dart';
import 'package:buddytalk/features/notifications/presentation/providers/notification_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _approvalRoomStatus;
  final List<ConversationModel> _createdRooms = [];
  final Map<String, List<MessageModel>> _messagesByRoom = {};
  void Function(MessageModel)? _onNewMessage;

  void emitRealtimeMessage(MessageModel msg) {
    _messagesByRoom.putIfAbsent(msg.conversationId, () => []).add(msg);
    _onNewMessage?.call(msg);
  }

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
        membershipStatus: _joined ? 'approved' : null,
      );

  ConversationModel _approvalRoom() => ConversationModel(
        id: 'room-approval',
        type: 'group',
        name: 'Nhóm Luyện IELTS Chuyên Sâu',
        description: 'Cần quản lý duyệt trước khi vào phòng.',
        level: 'B2',
        targetLang: 'en',
        maxMembers: 15,
        requireApproval: true,
        createdBy: 'u-owner-2',
        managerName: 'Trịnh Trung Kiên',
        memberCount: 5,
        isJoined: _approvalRoomStatus == 'approved',
        membershipStatus: _approvalRoomStatus,
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
    return [..._createdRooms, _sampleRoom(), _approvalRoom()];
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
    bool requireApproval = false,
  }) async {
    final created = ConversationModel(
      id: 'room-new-${_createdRooms.length + 1}',
      type: 'group',
      name: name.trim(),
      description: description.trim(),
      level: level,
      targetLang: targetLang,
      maxMembers: maxMembers,
      requireApproval: requireApproval,
      createdBy: createdBy,
      managerName: managerName,
      memberCount: 1,
      isJoined: true,
      membershipStatus: 'approved',
      myRole: 'owner',
    );
    _createdRooms.add(created);
    return created;
  }

  @override
  Future<void> joinRoom({
    required String conversationId,
    required String userId,
    bool requireApproval = false,
  }) async {
    if (conversationId == 'room-approval') {
      _approvalRoomStatus = requireApproval ? 'pending' : 'approved';
    } else {
      _joined = true;
    }
  }

  @override
  Future<void> leaveRoom({
    required String conversationId,
    required String userId,
  }) async {
    if (conversationId == 'room-approval') {
      _approvalRoomStatus = null;
    } else {
      _joined = false;
    }
  }

  @override
  Future<List<RoomJoinRequest>> fetchPendingRequests(
    String conversationId,
  ) async =>
      const [];

  @override
  Future<List<MessageModel>> fetchMessages(
    String conversationId, {
    int limit = 100,
  }) async =>
      List<MessageModel>.from(_messagesByRoom[conversationId] ?? const []);

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String content,
  }) async {
    final list = _messagesByRoom.putIfAbsent(conversationId, () => []);
    final saved = MessageModel(
      id: 'msg-${list.length + 1}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    list.add(saved);
    return saved;
  }

  @override
  Future<({String name, String? avatarUrl})> fetchSenderProfile(
    String userId,
  ) async =>
      (name: 'Trịnh Trung Kiên', avatarUrl: null);

  @override
  RealtimeChannel? subscribeToRoomMessages({
    required String conversationId,
    required void Function(MessageModel message) onNewMessage,
  }) {
    _onNewMessage = onNewMessage;
    return null;
  }

  @override
  Future<void> unsubscribeChannel(RealtimeChannel channel) async {}
}

class _FakeNotificationRepository extends NotificationRepository {
  void Function(NotificationModel)? _onNew;

  List<NotificationModel> _items = [
    NotificationModel(
      id: 'notif-1',
      userId: 'u-manager',
      actorId: 'u-requester',
      type: 'room_join_request',
      title: 'Yêu cầu tham gia phòng mới',
      body: 'Nguyễn Minh Anh xin tham gia phòng "Nhóm Luyện IELTS Chuyên Sâu".',
      referenceId: 'room-approval',
      isRead: false,
      createdAt: DateTime.now(),
    ),
  ];

  void emitRealtime(NotificationModel notification) {
    _items = [notification, ..._items];
    _onNew?.call(notification);
  }

  @override
  bool get isReady => true;

  @override
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    return _items.where((n) => n.userId == userId).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    _items = _items
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
  }

  @override
  RealtimeChannel? subscribeToUserNotifications({
    required String userId,
    required void Function(NotificationModel notification) onNewNotification,
  }) {
    _onNew = onNewNotification;
    return null;
  }

  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {}
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
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider(
              repository: _FakeNotificationRepository(),
            ),
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
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider(
              repository: _FakeNotificationRepository(),
            ),
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

    final chatRepo = _FakeChatRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(repository: authRepo),
          ),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => ChatProvider(repository: chatRepo),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ChatRoomsTab())),
      ),
    );
    await tester.pumpAndSettle();

    // Chuyển sang tab Khám phá phòng học (gồm 1 phòng mở + 1 phòng cần kiểm duyệt)
    await tester.tap(find.text('Khám phá (2)'));
    await tester.pumpAndSettle();

    expect(find.text('CLB Luyện Tiếng Anh Giao Tiếp'), findsOneWidget);
    expect(find.text('Quản lý: Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Tham gia'), findsOneWidget);
    expect(find.text('Xin tham gia'), findsOneWidget);
    expect(find.text('Cần duyệt'), findsOneWidget);
    expect(find.text('Hiển thị 1–2 trong tổng số 2 phòng'), findsOneWidget);

    // Bấm Xin tham gia ở phòng cần duyệt -> chuyển sang Chờ duyệt
    await tester.tap(find.text('Xin tham gia'));
    await tester.pumpAndSettle();
    expect(find.text('Chờ duyệt'), findsOneWidget);

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

    // Gửi tin nhắn thật vào repository & nhận tin nhắn Realtime từ người khác
    await tester.enterText(
      find.byType(TextField).last,
      'Hello everyone!',
    );
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pumpAndSettle();
    expect(find.text('Hello everyone!'), findsOneWidget);

    chatRepo.emitRealtimeMessage(
      MessageModel(
        id: 'msg-rt-1',
        conversationId: 'room-1',
        senderId: 'u-other',
        senderName: 'Trịnh Trung Kiên',
        content: 'Hi! Ready to practice?',
        createdAt: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hi! Ready to practice?'), findsOneWidget);
    expect(find.textContaining('Trịnh Trung Kiên'), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại danh sách phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng của tôi (2)'), findsOneWidget);
  });

  testWidgets('NotificationBellButton xổ dropdown kiểu Facebook & tự đồng bộ phòng khi nhận duyệt Realtime', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final authRepo = _FakeAuthRepository(
      initialProfile: const ProfileModel(
        userId: 'u-manager',
        displayName: 'Phạm Văn Hưng',
        onboardingCompleted: true,
      ),
    );
    final chatRepo = _FakeChatRepository();
    final notifRepo = _FakeNotificationRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(repository: authRepo),
          ),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => ChatProvider(repository: chatRepo),
          ),
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider(repository: notifRepo),
          ),
        ],
        child: const MaterialApp(home: AuthGuard(child: MainLayout())),
      ),
    );
    await tester.pumpAndSettle();

    // Badge số lượng chưa đọc = 1 hiển thị cạnh chuông thông báo
    expect(find.byTooltip('Thông báo'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Bấm vào chuông -> xổ dropdown kiểu Facebook (Tất cả / Chưa đọc)
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Chưa đọc (1)'), findsOneWidget);
    expect(find.text('Xem & Duyệt'), findsOneWidget);
    expect(find.text('Đọc tất cả'), findsOneWidget);

    // Đánh dấu đọc tất cả -> xóa badge đỏ & chuyển tab Chưa đọc sẽ báo đã đọc hết
    await tester.tap(find.text('Đọc tất cả'));
    await tester.pumpAndSettle();

    expect(find.text('Đọc tất cả'), findsNothing);
    await tester.tap(find.text('Chưa đọc'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã đọc hết thông báo.'), findsOneWidget);

    // Giả lập nhận sự kiện Realtime được duyệt phòng -> badge nhảy lên 1 ngay lập tức
    notifRepo.emitRealtime(
      NotificationModel(
        id: 'notif-2',
        userId: 'u-manager',
        type: 'room_join_approved',
        title: 'Đã được duyệt vào phòng học',
        body: 'Quản lý phòng đã duyệt bạn vào phòng.',
        referenceId: 'room-approval',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa đọc (1)'), findsOneWidget);

    // Bấm lại vào chuông để đóng dropdown
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Tất cả'), findsNothing);
  });
}
