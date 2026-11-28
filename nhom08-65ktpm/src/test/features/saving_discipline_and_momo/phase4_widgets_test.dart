import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/deposit_record.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/momo_fund_config.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/saving_plan.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/approve_receipt_screen.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/deposit_receipt_sheet.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/momo_fund_screen.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/widgets/deposit_due_warning_banner.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/presentation/widgets/fund_progress_card.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/saving_streak_calculator.dart';

void main() {
  group('FundProgressCard Widget Tests', () {
    testWidgets('shows percentage progress below 100%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FundProgressCard(
              collectedAmount: 5000000,
              targetAmount: 10000000,
              memberCount: 4,
              cycleLabel: 'Kỳ 5/10',
              installmentText: '250.000đ / kỳ',
              onDepositPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('5.000.000đ'), findsOneWidget);
      expect(find.text('Hoàn thành 100% 🎉'), findsNothing);
    });

    testWidgets('shows celebratory 100% badge and banner when target is reached', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FundProgressCard(
              collectedAmount: 8450000,
              targetAmount: 8450000,
              memberCount: 4,
              cycleLabel: 'Kỳ 10/10',
              installmentText: '212.000đ / kỳ',
              onDepositPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Hoàn thành 100% 🎉'), findsOneWidget);
      expect(
        find.text('Quỹ nhóm đã đạt 100% mục tiêu! Cả nhóm sẵn sàng lên đường thôi!'),
        findsOneWidget,
      );
    });
  });

  group('ApproveReceiptScreen Widget Tests', () {
    testWidgets('approving a pending receipt moves it to Approved and updates fund', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_widget_approve';
      await repo.saveFundConfig(
        MoMoFundConfig(
          tripId: tripId,
          fundName: 'Quỹ Test',
          hostUserId: 'host_1',
          hostName: 'An',
          momoPhoneNumber: '0912345678',
          targetTotalAmount: 1000000,
          currentCollectedAmount: 0,
          updatedAt: DateTime(2026, 11, 25),
        ),
      );
      await repo.submitDeposit(
        DepositRecord(
          id: 'dep_ui_1',
          tripId: tripId,
          memberId: 'm2',
          memberName: 'Nguyễn Xuân Bình',
          amount: 212000,
          installmentIndex: 6,
          depositDate: DateTime(2026, 11, 26),
          note: 'Đóng quỹ kỳ 6',
          emotionTag: '🔥',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: ApproveReceiptScreen(tripId: tripId, reviewerId: 'host_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duyệt biên lai (1)'), findsOneWidget);
      expect(find.text('Nguyễn Xuân Bình'), findsOneWidget);

      await tester.tap(find.text('Xác nhận hợp lệ'));
      await tester.pumpAndSettle();

      expect(find.text('Duyệt biên lai (0)'), findsOneWidget);
      final updatedFund = await repo.getFundConfig(tripId);
      expect(updatedFund!.currentCollectedAmount, 212000);

      await tester.tap(find.text('Đã duyệt'));
      await tester.pumpAndSettle();
      expect(find.text('Đã xác nhận'), findsOneWidget);
    });

    testWidgets('rejecting a pending receipt with reason moves it to Rejected without disposal error', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_widget_reject';
      await repo.submitDeposit(
        DepositRecord(
          id: 'dep_ui_reject_1',
          tripId: tripId,
          memberId: 'm3',
          memberName: 'Đỗ Tùng Khánh',
          amount: 212000,
          installmentIndex: 6,
          depositDate: DateTime(2026, 11, 26),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: ApproveReceiptScreen(tripId: tripId, reviewerId: 'host_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Từ chối').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ảnh bị mờ');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Từ chối'),
        ),
      );
      // Pump frames incrementally during dialog close animation to catch disposal/dependent assertions.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Duyệt biên lai (0)'), findsOneWidget);
      await tester.tap(find.text('Từ chối').first);
      await tester.pumpAndSettle();
      expect(find.text('Lý do từ chối: Ảnh bị mờ'), findsOneWidget);
    });
  });

  group('Fallback ProviderScope Compatibility Tests', () {
    testWidgets('MomoFundScreen and ApproveReceiptScreen render without root ProviderScope', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MomoFundScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quỹ MoMo'), findsOneWidget);
      expect(find.text('Tiến độ Quỹ tích lũy'), findsOneWidget);

      await tester.ensureVisible(find.text('Nộp biên lai'));
      await tester.tap(find.text('Nộp biên lai'));
      await tester.pumpAndSettle();
      expect(find.text('Gửi Trưởng nhóm xác nhận'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: ApproveReceiptScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Duyệt biên lai'), findsOneWidget);
    });

    testWidgets('DepositReceiptSheet displays inline validation error inside sheet when no photo is picked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DepositReceiptSheet(fundName: 'Quỹ Test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Gửi Trưởng nhóm xác nhận'));
      await tester.tap(find.text('Gửi Trưởng nhóm xác nhận'));
      await tester.pumpAndSettle();

      // Inline error rendered directly inside the sheet (not only in a hidden SnackBar behind a modal).
      expect(
        find.descendant(
          of: find.byType(DepositReceiptSheet),
          matching: find.text('Vui lòng chọn ảnh chụp biên lai giao dịch MoMo'),
        ),
        findsOneWidget,
      );
    });
  });

  group('DepositDueWarningBanner Widget Tests', () {
    testWidgets('renders due-today warning and fires action callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DepositDueWarningBanner(
              reminder: TodayDepositReminder(
                shouldWarn: true,
                urgency: DepositReminderUrgency.dueToday,
                frequency: SavingFrequency.daily,
                installmentIndex: 1,
                dueDate: DateTime(2026, 11, 27),
                amountDue: 50000,
              ),
              onDepositTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Hôm nay cần nạp quỹ (Hàng ngày)'), findsOneWidget);
      expect(find.text('Nộp ngay'), findsOneWidget);

      await tester.tap(find.text('Nộp ngay'));
      expect(tapped, isTrue);
    });

    testWidgets('MomoFundScreen shows warning banner when member has daily plan unpaid today', (tester) async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_warn_ui';
      final now = DateTime.now();
      await repo.saveSavingPlan(
        SavingPlan(
          id: '${tripId}_m_daily',
          tripId: tripId,
          memberId: 'm_daily',
          memberName: 'Nguyễn Văn A',
          targetAmount: 500000,
          frequency: SavingFrequency.daily,
          installmentAmount: 50000,
          totalInstallments: 10,
          startDate: DateTime(now.year, now.month, now.day),
          deadlineDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 10)),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [savingRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: MomoFundScreen(
              tripId: tripId,
              memberId: 'm_daily',
              memberName: 'Nguyễn Văn A',
              isHost: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hôm nay cần nạp quỹ (Hàng ngày)'), findsOneWidget);
      expect(find.text('Nộp ngay'), findsOneWidget);
      expect(find.textContaining('Kỳ nạp tới:'), findsOneWidget);
      expect(find.byIcon(Icons.event_rounded), findsWidgets);
    });
  });
}
