import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/deposit_record.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/momo_fund_config.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/saving_plan.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/approve_receipt_screen.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/deposit_receipt_sheet.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/momo_fund_screen.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/setup_momo_sheet.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/widgets/daily_you_streak_calendar.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/widgets/deposit_due_warning_banner.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/widgets/saving_journal_dialog.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/momo_fund_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_plan_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';
import 'package:travel_buddy/models/trip_member.dart';
import 'package:travel_buddy/models/trip_model.dart';

class _FailingPlanRepository extends InMemorySavingRepository {
  @override
  Future<void> saveSavingPlan(SavingPlan plan) async {
    throw Exception('Firestore plan write failed');
  }
}

class _FailingStreamRepository extends InMemorySavingRepository {
  @override
  Stream<MoMoFundConfig?> watchFundConfig(String tripId) {
    return Stream<MoMoFundConfig?>.error(Exception('Permission denied'));
  }
}

void main() {
  group('MoMoFundNotifier & SavingPlanNotifier Phase 2 fixes', () {
    test('saveFundConfig preserves existing currentCollectedAmount when state.value is null', () async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_preserve_collected';
      await repo.saveFundConfig(
        MoMoFundConfig(
          tripId: tripId,
          fundName: 'Quỹ cũ',
          hostUserId: 'host_1',
          hostName: 'An',
          momoPhoneNumber: '0912345678',
          targetTotalAmount: 5000000,
          currentCollectedAmount: 1750000,
          updatedAt: DateTime(2026, 11, 20),
        ),
      );

      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Call saveFundConfig directly without watching momoFundProvider first.
      final updated = await container.read(momoFundProvider(tripId).notifier).saveFundConfig(
            fundName: 'Quỹ mới',
            hostUserId: 'host_1',
            hostName: 'An',
            momoPhoneNumber: '0987654321',
            targetTotalAmount: 6000000,
          );

      expect(updated.currentCollectedAmount, 1750000);
      final persisted = await repo.getFundConfig(tripId);
      expect(persisted?.currentCollectedAmount, 1750000);
      expect(persisted?.fundName, 'Quỹ mới');
    });

    test('createSavingPlan rethrows repository error cleanly instead of LateInitializationError', () async {
      final repo = _FailingPlanRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const params = SavingPlanParams(tripId: 'trip_err_plan', memberId: 'm1');
      await expectLater(
        () => container.read(savingPlanProvider(params).notifier).createSavingPlan(
              memberName: 'Bình',
              targetAmount: 2000000,
              startDate: DateTime(2026, 11, 28),
              deadlineDate: DateTime(2026, 12, 28),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MomoFundScreen real-data sync & host gating', () {
    testWidgets('merges real TripMembers without SavingPlans into leaderboard and gates non-host', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_live_members';
      final now = DateTime(2026, 11, 28);

      repo.seedTripSummary(
        TripModel(
          id: tripId,
          title: 'Phú Quốc',
          destination: 'Phú Quốc',
          startDate: now.add(const Duration(days: 30)),
          endDate: now.add(const Duration(days: 33)),
          hostId: 'host_u1',
          memberIds: const ['host_u1', 'member_u2'],
          inviteCode: 'TBPQ01',
          targetBudget: 4000000,
          perMemberTarget: 2000000,
          createdAt: now,
          updatedAt: now,
        ),
      );
      repo.seedTripMembers(tripId, [
        TripMember(
          userId: 'host_u1',
          displayName: 'Đỗ Đình An',
          role: TripRole.host,
          targetContribution: 2000000,
          contributedAmount: 500000,
          joinedAt: now,
        ),
        TripMember(
          userId: 'member_u2',
          displayName: 'Nguyễn Xuân Bình',
          role: TripRole.member,
          targetContribution: 2000000,
          contributedAmount: 0,
          joinedAt: now.add(const Duration(minutes: 1)),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: MomoFundScreen(
              tripId: tripId,
              memberId: 'member_u2',
              memberName: 'Nguyễn Xuân Bình',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Non-host sees waiting state instead of host-only setup controls.
      expect(find.text('Chờ Trưởng nhóm liên kết MoMo'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // Scroll down to leaderboard and verify both real TripMembers appear.
      await tester.scrollUntilVisible(
        find.textContaining('Đỗ Đình An'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Đỗ Đình An'), findsOneWidget);
      expect(find.textContaining('Nguyễn Xuân Bình'), findsOneWidget);
    });

    testWidgets('shows error banner with retry button when stream fails', (tester) async {
      final repo = _FailingStreamRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: MomoFundScreen(
              tripId: 'trip_stream_err',
              memberId: 'm1',
              memberName: 'Test User',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Không thể đồng bộ dữ liệu quỹ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('prevents check-in on days before member joinedAt and allows check-in on joinedAt', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_joined_guard';
      const memberId = 'm_joined';
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      repo.seedTripMembers(tripId, [
        TripMember(
          userId: memberId,
          displayName: 'Member Joined Today',
          role: TripRole.member,
          targetContribution: 1000000,
          contributedAmount: 0,
          joinedAt: today,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DailyYouStreakCalendar(
                  tripId: tripId,
                  memberId: memberId,
                  showDepositWarning: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // If today is the 1st of the month, navigate to previous month to tap yesterday.
      if (yesterday.month != today.month) {
        await tester.tap(find.byIcon(Icons.chevron_left_rounded));
        await tester.pumpAndSettle();
      }

      // Tapping yesterday (before joinedAt) must NOT open SavingJournalDialog.
      final yesterdayFinder = find
          .descendant(
            of: find.byType(GridView),
            matching: find.text('${yesterday.day}'),
          )
          .first;
      await tester.ensureVisible(yesterdayFinder);
      await tester.pumpAndSettle();
      await tester.tap(yesterdayFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SavingJournalDialog), findsNothing);
      expect(find.text('Bạn chưa tham gia chuyến đi vào ngày này.'), findsOneWidget);

      // Navigate back to current month if we moved to previous month.
      if (yesterday.month != today.month) {
        await tester.tap(find.byIcon(Icons.chevron_right_rounded));
        await tester.pumpAndSettle();
      }

      // Tapping today (joinedAt) MUST open SavingJournalDialog.
      final todayFinder = find
          .descendant(
            of: find.byType(GridView),
            matching: find.text('${today.day}'),
          )
          .first;
      await tester.ensureVisible(todayFinder);
      await tester.pumpAndSettle();
      await tester.tap(todayFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SavingJournalDialog), findsOneWidget);
    });

    testWidgets('SetupMomoSheet saves split frequency & amount into MoMoFundConfig', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_split_save';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const SetupMomoSheet(
                      tripId: tripId,
                      hostUserId: 'host_1',
                      hostName: 'Host User',
                      initialFundName: 'Quỹ Phú Quốc',
                      targetTotalAmount: 6000000,
                      memberCount: 2,
                      initialPhoneNumber: '0912345678',
                    ),
                  ),
                  child: const Text('Open Setup'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Setup'));
      await tester.pumpAndSettle();

      // Switch cycle from default weekly to daily (6,000,000 / 2 / 30 = 100,000).
      await tester.tap(find.text('Theo ngày'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      final saved = await repo.getFundConfig(tripId);
      expect(saved, isNotNull);
      expect(saved!.defaultFrequency, SavingFrequency.daily);
      expect(saved.suggestedPerMemberAmount, 100000);
    });

    testWidgets('MomoFundScreen syncs saved split config to FundProgressCard & DepositReceiptSheet', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_split_sync_ui';
      await repo.saveFundConfig(
        MoMoFundConfig(
          tripId: tripId,
          fundName: 'Quỹ Phú Quốc',
          hostUserId: 'host_1',
          hostName: 'Host User',
          momoPhoneNumber: '0912345678',
          targetTotalAmount: 6000000,
          defaultFrequency: SavingFrequency.daily,
          suggestedPerMemberAmount: 100000,
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: MomoFundScreen(
              tripId: tripId,
              memberId: 'member_2',
              memberName: 'Member Two',
              isHost: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DepositDueWarningBanner), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Nộp biên lai'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('100.000đ / ngày (đề xuất)'), findsOneWidget);
      expect(find.textContaining('Kỳ tới: Hôm nay'), findsOneWidget);

      // Verify today's due-day icon (Icons.event_rounded) displays on the calendar even without a SavingPlan.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.event_rounded),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byIcon(Icons.event_rounded), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Nộp biên lai'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Nộp biên lai'));
      await tester.pumpAndSettle();

      expect(find.byType(DepositReceiptSheet), findsOneWidget);
      expect(find.text('Nạp quỹ Theo ngày'), findsOneWidget);
      expect(find.widgetWithText(TextField, '100.000'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '100.000'), '1500000');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '1.500.000'), findsOneWidget);
    });

    test('saveFundConfig updates TripMember targetContribution and existing SavingPlans atomically', () async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_propagate_targets';
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final deadline = start.add(const Duration(days: 60));

      repo.seedTripMembers(tripId, [
        TripMember(
          userId: 'host_1',
          displayName: 'Host',
          role: TripRole.host,
          targetContribution: 1000000,
          contributedAmount: 0,
          joinedAt: now,
        ),
        TripMember(
          userId: 'member_2',
          displayName: 'Member Two',
          role: TripRole.member,
          targetContribution: 1000000,
          contributedAmount: 0,
          joinedAt: now,
        ),
      ]);

      await repo.saveSavingPlan(
        SavingPlan(
          id: '${tripId}_member_2',
          tripId: tripId,
          memberId: 'member_2',
          memberName: 'Member Two',
          targetAmount: 1000000,
          frequency: SavingFrequency.weekly,
          installmentAmount: 125000,
          totalInstallments: 8,
          startDate: start,
          deadlineDate: deadline,
        ),
      );

      await repo.saveFundConfig(
        MoMoFundConfig(
          tripId: tripId,
          fundName: 'Quỹ Hội An',
          hostUserId: 'host_1',
          hostName: 'Host',
          momoPhoneNumber: '0912345678',
          targetTotalAmount: 6000000,
          defaultFrequency: SavingFrequency.daily,
          suggestedPerMemberAmount: 100000,
          updatedAt: now,
        ),
      );

      final updatedMembers = await repo.watchTripMembers(tripId).first;
      expect(updatedMembers, hasLength(2));
      expect(updatedMembers.every((m) => m.targetContribution == 3000000), isTrue);

      final updatedPlan = await repo.getSavingPlan(tripId, 'member_2');
      expect(updatedPlan, isNotNull);
      expect(updatedPlan!.targetAmount, 3000000);
      expect(updatedPlan.frequency, SavingFrequency.daily);
      expect(updatedPlan.totalInstallments, 60);
      expect(updatedPlan.installmentAmount, 50000);
    });

    testWidgets('SetupMomoSheet preserves scanned QR & frequency when reopened with initialQrCodeUrl', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_reopen_qr';
      const rawQr = '00020101021138570010A00000072701270006970454011309123456785204000053037045802VN5909MOMO TEST6304ABCD';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SetupMomoSheet(
                  tripId: tripId,
                  hostUserId: 'host_1',
                  hostName: 'Host',
                  initialFundName: 'Quỹ QR Test',
                  targetTotalAmount: 4000000,
                  memberCount: 2,
                  initialFrequency: SavingFrequency.monthly,
                  initialPhoneNumber: '0912345678',
                  initialQrCodeUrl: rawQr,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã nhận diện mã QR Quỹ nhóm MoMo'), findsOneWidget);
      expect(find.textContaining('2.000.000đ/tháng'), findsOneWidget);

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      final saved = await repo.getFundConfig(tripId);
      expect(saved, isNotNull);
      expect(saved!.defaultFrequency, SavingFrequency.monthly);
      expect(saved.suggestedPerMemberAmount, 2000000);
      expect(saved.qrCodeUrl, rawQr);
    });

    testWidgets('ApproveReceiptScreen configures loadingBuilder & broken-image errorBuilder for Supabase HTTPS URLs', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_receipt_img';
      await repo.submitDeposit(
        DepositRecord(
          id: 'dep_https_1',
          tripId: tripId,
          memberId: 'm1',
          memberName: 'Nguyễn Xuân Bình',
          amount: 200000,
          depositDate: DateTime.now(),
          receiptImageUrl: 'https://example.supabase.co/storage/v1/object/public/receipts/test.jpg',
          status: DepositStatus.pending,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: ApproveReceiptScreen(
              tripId: tripId,
              reviewerId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final imageWidget = tester.widget<Image>(find.byType(Image).first);
      expect(imageWidget.loadingBuilder, isNotNull);
      expect(imageWidget.errorBuilder, isNotNull);

      await tester.pumpAndSettle();
      // In widget tests without a real HTTP server, network image falls back cleanly to broken_image_outlined.
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });
  });
}
