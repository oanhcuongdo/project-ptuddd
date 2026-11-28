import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:travel_buddy/core/utils/formatters.dart';
import 'package:travel_buddy/features/auth_and_group/presentation/login_screen.dart';
import 'package:travel_buddy/features/auth_and_group/presentation/members_profile_screen.dart';
import 'package:travel_buddy/features/auth_and_group/presentation/trip_list_screen.dart';
import 'package:travel_buddy/features/auth_and_group/repository/auth_repository.dart';
import 'package:travel_buddy/features/auth_and_group/repository/trip_repository.dart';
import 'package:travel_buddy/models/app_user.dart';

void main() {
  group('AppFormatters & InviteCode Helpers', () {
    test('formatVnd and parseVnd handle Vietnamese currency accurately', () {
      expect(AppFormatters.formatVnd(8450000), '8.450.000đ');
      expect(AppFormatters.parseVnd('8.450.000đ'), 8450000);
      expect(AppFormatters.parseVnd('abc'), 0);
    });

    test('normalizeInviteCode extracts code from QR deeplink or plain text', () {
      expect(
        TripRepository.normalizeInviteCode('travelbuddy://join?code=tb8k4m'),
        'TB8K4M',
      );
      expect(
        TripRepository.normalizeInviteCode('https://travelbuddy.app/join/ab12cd'),
        'AB12CD',
      );
      expect(TripRepository.normalizeInviteCode(' tb99xy '), 'TB99XY');
    });

    test('generateInviteCode produces 6-char uppercase code starting with TB', () {
      final code = TripRepository.generateInviteCode();
      expect(code.length, 6);
      expect(code.startsWith('TB'), isTrue);
    });
  });

  group('InMemoryAuthRepository & InMemoryTripRepository', () {
    test('createTrip and joinTripByCode update members and perMemberTarget', () async {
      final authRepo = InMemoryAuthRepository(seedSignedIn: false);
      final host = await authRepo.registerWithEmailAndPassword(
        email: 'an@tlu.edu.vn',
        password: 'password123',
        displayName: 'Đỗ Đình An',
      );
      final tripRepo = InMemoryTripRepository();

      final created = await tripRepo.createTrip(
        host: host,
        title: 'Sapa 3N2Đ',
        destination: 'Sa Pa',
        startDate: DateTime(2026, 12, 10),
        endDate: DateTime(2026, 12, 12),
        targetBudget: 6000000,
        customInviteCode: 'SP2026',
      );

      expect(created.inviteCode, 'SP2026');
      expect(created.memberIds, [host.uid]);
      expect(created.perMemberTarget, 6000000);

      final now = DateTime.now();
      final member = AppUser(
        uid: 'member-2',
        email: 'binh@tlu.edu.vn',
        displayName: 'Nguyễn Xuân Bình',
        createdAt: now,
        updatedAt: now,
      );

      final joined = await tripRepo.joinTripByCode(
        rawCode: 'travelbuddy://join?code=sp2026',
        user: member,
      );
      expect(joined.memberIds, [host.uid, member.uid]);
      expect(joined.perMemberTarget, 3000000);

      // Re-joining same trip is idempotent.
      final joinedAgain = await tripRepo.joinTripByCode(
        rawCode: 'SP2026',
        user: member,
      );
      expect(joinedAgain.memberIds.length, 2);
    });

    test('joinTripByCode throws TripFailure for unknown code', () async {
      final authRepo = InMemoryAuthRepository();
      final tripRepo = InMemoryTripRepository();
      expect(
        () => tripRepo.joinTripByCode(
          rawCode: 'INVALID',
          user: authRepo.currentUser!,
        ),
        throwsA(isA<TripFailure>()),
      );
    });
  });

  group('auth_and_group Screens Widget Tests', () {
    testWidgets('LoginScreen signs in and navigates to /trips', (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/trips',
            builder: (_, _) => const Scaffold(body: Text('Trips Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.enterText(find.byType(TextField).at(0), 'an@tlu.edu.vn');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Trips Home'), findsOneWidget);
    });

    testWidgets('TripListScreen renders live trips from repository', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TripListScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đà Lạt 4N3Đ'), findsOneWidget);
      expect(find.text('Mã mời: TB8K4M'), findsOneWidget);
    });

    testWidgets('MembersProfileScreen renders trip members', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MembersProfileScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thành viên (4)'), findsOneWidget);
      expect(find.text('Đỗ Đình An'), findsOneWidget);
    });
  });
}
