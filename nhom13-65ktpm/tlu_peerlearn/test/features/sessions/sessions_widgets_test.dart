import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/sessions/models/tutoring_session.dart';
import 'package:tlu_peerlearn/features/sessions/screens/session_detail_screen.dart';
import 'package:tlu_peerlearn/features/sessions/widgets/create_session_dialog.dart';

void main() {
  group('Sessions Widgets Tests (SES)', () {
    testWidgets('CreateSessionDialog validates required title (SES-01)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateSessionDialog(
              onSubmit: ({
                required title,
                required scheduledStart,
                required scheduledEnd,
                required mode,
                locationOrLink,
                plannedContent,
              }) async {},
            ),
          ),
        ),
      );

      expect(find.text('Lên lịch buổi học mới (SES-01)'), findsOneWidget);

      // Bấm Lưu khi chưa nhập tiêu đề
      await tester.tap(find.text('Lưu lịch học'));
      await tester.pump();

      expect(find.text('Vui lòng nhập tiêu đề buổi học'), findsOneWidget);
    });

    testWidgets('SessionDetailScreen displays mentee independent confirmation (SES-03, BR-09, BR-10)',
        (tester) async {
      final now = DateTime.now();
      final session = TutoringSession(
        id: 's1',
        roomId: 'r1',
        mentorId: 'm1',
        title: 'Ôn tập B-Tree & Indexing',
        scheduledStart: now,
        scheduledEnd: now.add(const Duration(hours: 2)),
        mode: 'offline',
        locationOrLink: 'Thư viện TLU tầng 3',
        plannedContent: 'Cấu trúc chỉ mục trong RDBMS',
        status: 'scheduled',
        createdAt: now,
      );

      final attendances = [
        const SessionAttendance(
          id: 'att1',
          sessionId: 's1',
          menteeId: 'mentee_1',
          menteeName: 'Nguyễn Văn Mentee',
          mentorMarkedStatus: 'present',
          menteeConfirmed: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SessionDetailScreen(
              session: session,
              currentUserId: 'mentee_1',
              isMentor: false,
              initialAttendances: attendances,
              initialEvidences: const [],
            ),
          ),
        ),
      );

      expect(find.text('Ôn tập B-Tree & Indexing'), findsOneWidget);
      expect(find.text('Xác nhận tham gia buổi học (SES-03)'), findsOneWidget);
      expect(find.text('Bấm để xác nhận tham gia'), findsOneWidget);

      // Mentee bấm xác nhận độc lập (SES-03)
      await tester.tap(find.text('Bấm để xác nhận tham gia'));
      await tester.pump();

      expect(find.text('Bạn đã xác nhận tham gia buổi học (SES-03)'), findsOneWidget);
    });

    testWidgets('SessionDetailScreen displays mentor report completion section (SES-02)',
        (tester) async {
      final now = DateTime.now();
      final session = TutoringSession(
        id: 's1',
        roomId: 'r1',
        mentorId: 'm1',
        title: 'Ôn tập SQL nâng cao',
        scheduledStart: now,
        scheduledEnd: now.add(const Duration(hours: 2)),
        mode: 'online',
        status: 'scheduled',
        createdAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SessionDetailScreen(
              session: session,
              currentUserId: 'm1',
              isMentor: true,
              initialAttendances: const [],
              initialEvidences: const [],
            ),
          ),
        ),
      );

      expect(find.text('Ghi nhận nội dung buổi học (Mentor)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Hoàn tất báo cáo buổi học (SES-02)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Hoàn tất báo cáo buổi học (SES-02)'), findsOneWidget);
    });
  });
}
