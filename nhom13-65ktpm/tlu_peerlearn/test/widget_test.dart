import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/admin/domain/admin_models.dart';
import 'package:tlu_peerlearn/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:tlu_peerlearn/features/admin/presentation/admin_session_logs_screen.dart';
import 'package:tlu_peerlearn/features/auth_profile/domain/program_registration.dart';
import 'package:tlu_peerlearn/features/auth_profile/domain/user_profile.dart';
import 'package:tlu_peerlearn/features/auth_profile/presentation/course_registration_screen.dart';
import 'package:tlu_peerlearn/features/auth_profile/presentation/login_screen.dart';
import 'package:tlu_peerlearn/features/auth_profile/presentation/profile_screen.dart';
import 'package:tlu_peerlearn/features/auth_profile/presentation/register_screen.dart';
import 'package:tlu_peerlearn/features/auth_profile/presentation/widgets/schedule_slot_picker.dart';

void main() {
  testWidgets('LoginScreen validates empty email and password', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('RegisterScreen validates required fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.tap(find.text('Đăng ký'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('ProfileScreen displays initial data and validates fullName',
      (tester) async {
    const profile = UserProfile(
      id: 'u1',
      email: 'minhanh@tlu.edu.vn',
      fullName: 'Phùng Minh Anh',
      studentId: '2351170574',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProfileScreen(initialProfile: profile)),
      ),
    );

    expect(find.text('minhanh@tlu.edu.vn'), findsOneWidget);
    expect(find.text('Phùng Minh Anh'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
  });

  testWidgets('ScheduleSlotPicker toggles slot index 0..20', (tester) async {
    int? toggled;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleSlotPicker(
            selectedSlots: const {0, 4},
            onToggleSlot: (idx) => toggled = idx,
          ),
        ),
      ),
    );

    expect(find.text('Khung lịch rảnh trong tuần (2/21 buổi)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('slot_2')));
    expect(toggled, 2);
  });

  testWidgets('CourseRegistrationScreen validates mentor grade',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CourseRegistrationScreen(
            initialCourses: [
              Course(id: 'c1', code: 'CSE204', name: 'Cơ sở dữ liệu'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mentor'));
    await tester.pump();

    await tester.ensureVisible(find.text('Lưu đăng ký'));
    await tester.tap(find.text('Lưu đăng ký'));
    await tester.pump();

    expect(find.text('Nhập điểm hợp lệ (0 - 10)'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen displays stats and filters rooms',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminDashboardScreen(
            initialStats: AdminOverviewStats(
              totalMentors: 4,
              totalMentees: 12,
              totalRooms: 3,
              totalSessions: 5,
              totalGeneratedSets: 8,
              totalQuizAttempts: 20,
            ),
            initialRooms: [
              AdminRoomSummary(
                id: 'r1',
                name: 'CSDL - Nhóm 01',
                roomCode: 'CSDL01',
                courseName: 'Cơ sở dữ liệu',
                mentorName: 'Phùng Minh Anh',
              ),
              AdminRoomSummary(
                id: 'r2',
                name: 'Java - Nhóm 02',
                roomCode: 'JAVA02',
                courseName: 'Lập trình Java',
                mentorName: 'Ngô Tuấn Anh',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('CSDL - Nhóm 01'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('CSDL - Nhóm 01'), findsOneWidget);
    expect(find.text('Java - Nhóm 02'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'CSDL');
    await tester.pump();

    expect(find.text('CSDL - Nhóm 01'), findsOneWidget);
    expect(find.text('Java - Nhóm 02'), findsNothing);
  });

  testWidgets('AdminSessionLogsScreen displays attendance comparison',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AdminSessionLogsScreen(
            initialLogs: [
              AdminSessionLog(
                id: 's1',
                title: 'Ôn tập JOIN',
                roomName: 'CSDL - Nhóm 01',
                mentorName: 'Phùng Minh Anh',
                scheduledStart: DateTime(2026, 11, 20, 9, 0),
                guidedContent: 'Hướng dẫn LEFT JOIN và INNER JOIN',
                attendances: const [
                  AdminSessionAttendance(
                    menteeName: 'Phạm Văn Phước',
                    mentorMarkedStatus: 'present',
                    menteeConfirmed: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Ôn tập JOIN'), findsOneWidget);
    await tester.tap(find.text('Ôn tập JOIN'));
    await tester.pumpAndSettle();

    expect(find.text('Phạm Văn Phước'), findsOneWidget);
    expect(find.text('Có mặt'), findsOneWidget);
    expect(find.text('Đã xác nhận'), findsOneWidget);
  });
}
