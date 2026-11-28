import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/deposit_record.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/momo_fund_config.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/saving_plan.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/receipt_approval_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_plan_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_streak_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';

class _FailingReceiptRepository extends InMemorySavingRepository {
  @override
  Future<void> submitDeposit(DepositRecord record, {File? receiptImage}) async {
    throw Exception('Upload failed');
  }

  @override
  Future<void> updateDepositStatus({
    required String tripId,
    required String depositId,
    required DepositStatus status,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    throw Exception('Transaction failed');
  }
}

void main() {
  group('DepositRecord rejectionReason serialization', () {
    test('round-trips rejectionReason through toMap and fromMap', () {
      final record = DepositRecord(
        id: 'dep_1',
        tripId: 'trip_1',
        memberId: 'm1',
        memberName: 'Nguyễn Xuân Bình',
        amount: 212000,
        depositDate: DateTime(2026, 11, 25),
        status: DepositStatus.rejected,
        approvedBy: 'host_1',
        rejectionReason: 'Ảnh bị mờ mã giao dịch',
      );

      final restored = DepositRecord.fromMap(record.toMap(), id: record.id);
      expect(restored.status, DepositStatus.rejected);
      expect(restored.rejectionReason, 'Ảnh bị mờ mã giao dịch');
    });

    test('round-trips termDueDate and termFrequency through toMap and fromMap', () {
      final record = DepositRecord(
        id: 'dep_term_snap',
        tripId: 'trip_1',
        memberId: 'm1',
        memberName: 'Nguyễn Xuân Bình',
        amount: 212000,
        installmentIndex: 2,
        depositDate: DateTime(2026, 11, 14),
        termDueDate: DateTime(2026, 11, 15),
        termFrequency: SavingFrequency.weekly,
      );

      final restored = DepositRecord.fromMap(record.toMap(), id: record.id);
      expect(restored.termDueDate, DateTime(2026, 11, 15));
      expect(restored.termFrequency, SavingFrequency.weekly);
    });
  });

  group('ReceiptApprovalProvider & Repository Tests', () {
    test('submitDeposit stores pending deposit and emits on trip and pending streams', () async {
      final repo = InMemorySavingRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const tripId = 'trip_phase4_submit';
      final allSub = container.listen(tripDepositsStreamProvider(tripId), (_, _) {});
      final pendingSub = container.listen(pendingDepositsStreamProvider(tripId), (_, _) {});
      addTearDown(allSub.close);
      addTearDown(pendingSub.close);

      final submitted = await container
          .read(receiptApprovalProvider(tripId).notifier)
          .submitDeposit(
            memberId: 'm2',
            memberName: 'Nguyễn Xuân Bình',
            amount: 212000,
            installmentIndex: 6,
            emotionTag: '🔥',
            note: 'Nhịn 2 ly trà sữa',
            receiptImageUrl: 'https://example.com/receipt.jpg',
          );

      expect(submitted.status, DepositStatus.pending);
      expect(submitted.amount, 212000);

      final pending = await repo.getPendingDeposits(tripId);
      expect(pending.length, 1);
      expect(pending.first.id, submitted.id);
      expect(pending.first.emotionTag, '🔥');
    });

    test('approveDeposit updates deposit, fund collected amount, saving plan, and streak', () async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_phase4_approve';
      const memberId = 'm2';

      await repo.saveFundConfig(
        MoMoFundConfig(
          tripId: tripId,
          fundName: 'Quỹ Đà Lạt',
          hostUserId: 'host_1',
          hostName: 'Đỗ Đình An',
          momoPhoneNumber: '0912345678',
          targetTotalAmount: 1000000,
          currentCollectedAmount: 400000,
          updatedAt: DateTime(2026, 11, 20),
        ),
      );
      await repo.saveSavingPlan(
        SavingPlan(
          id: '${tripId}_$memberId',
          tripId: tripId,
          memberId: memberId,
          memberName: 'Nguyễn Xuân Bình',
          targetAmount: 500000,
          paidAmount: 200000,
          frequency: SavingFrequency.weekly,
          installmentAmount: 100000,
          totalInstallments: 5,
          completedInstallments: 2,
          startDate: DateTime(2026, 11, 1),
          deadlineDate: DateTime(2026, 12, 5),
        ),
      );

      final deposit = DepositRecord(
        id: 'dep_approve_1',
        tripId: tripId,
        memberId: memberId,
        memberName: 'Nguyễn Xuân Bình',
        amount: 100000,
        installmentIndex: 3,
        depositDate: DateTime.now(),
        status: DepositStatus.pending,
      );
      await repo.submitDeposit(deposit);

      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(receiptApprovalProvider(tripId).notifier).approveDeposit(
            depositId: deposit.id,
            reviewerId: 'host_1',
          );

      final fund = await repo.getFundConfig(tripId);
      expect(fund!.currentCollectedAmount, 500000);

      final plan = await repo.getSavingPlan(tripId, memberId);
      expect(plan!.paidAmount, 300000);
      expect(plan.completedInstallments, 3);

      final streak = await repo.getMemberStreak(tripId, memberId);
      expect(streak.totalDisciplinedDays, 1);
      expect(streak.currentStreak, 1);

      final pending = await repo.getPendingDeposits(tripId);
      expect(pending, isEmpty);

      // Re-approving same deposit must not double-count amounts.
      await container.read(receiptApprovalProvider(tripId).notifier).approveDeposit(
            depositId: deposit.id,
            reviewerId: 'host_1',
          );
      final fundAfterRepeat = await repo.getFundConfig(tripId);
      expect(fundAfterRepeat!.currentCollectedAmount, 500000);
    });

    test('approveDeposit works safely when fund config or saving plan does not exist', () async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_phase4_no_plan';
      final deposit = DepositRecord(
        id: 'dep_orphan',
        tripId: tripId,
        memberId: 'm_orphan',
        memberName: 'Thành viên mới',
        amount: 212000,
        depositDate: DateTime(2026, 11, 25),
        status: DepositStatus.pending,
      );
      await repo.submitDeposit(deposit);

      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(receiptApprovalProvider(tripId).notifier).approveDeposit(
            depositId: deposit.id,
            reviewerId: 'host_1',
          );

      final streak = await repo.getMemberStreak(tripId, 'm_orphan');
      expect(streak.totalDisciplinedDays, 1);
      expect(streak.depositDates, ['2026-11-25']);
    });

    test('rejectDeposit saves rejectionReason and leaves fund and streak unchanged', () async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_phase4_reject';
      await repo.saveFundConfig(
        MoMoFundConfig(
          tripId: tripId,
          fundName: 'Quỹ Đà Lạt',
          hostUserId: 'host_1',
          hostName: 'Đỗ Đình An',
          momoPhoneNumber: '0912345678',
          targetTotalAmount: 1000000,
          currentCollectedAmount: 400000,
          updatedAt: DateTime(2026, 11, 20),
        ),
      );
      final deposit = DepositRecord(
        id: 'dep_reject_1',
        tripId: tripId,
        memberId: 'm3',
        memberName: 'Đỗ Tùng Khánh',
        amount: 212000,
        depositDate: DateTime(2026, 11, 25),
        status: DepositStatus.pending,
      );
      await repo.submitDeposit(deposit);

      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(receiptApprovalProvider(tripId).notifier).rejectDeposit(
            depositId: deposit.id,
            reviewerId: 'host_1',
            reason: 'Thiếu mã giao dịch MoMo',
          );

      final fund = await repo.getFundConfig(tripId);
      expect(fund!.currentCollectedAmount, 400000);

      final streak = await repo.getMemberStreak(tripId, 'm3');
      expect(streak.totalDisciplinedDays, 0);

      final allDeposits = await repo.watchTripDeposits(tripId).first;
      expect(allDeposits.single.status, DepositStatus.rejected);
      expect(allDeposits.single.rejectionReason, 'Thiếu mã giao dịch MoMo');
    });

    test('rethrows repository failures, records AsyncError, and does not save journal entry', () async {
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(_FailingReceiptRepository())],
      );
      addTearDown(container.dispose);

      const tripId = 'trip_phase4_fail';
      const params = SavingPlanParams(tripId: tripId, memberId: 'm1');
      await expectLater(
        container.read(receiptApprovalProvider(tripId).notifier).submitDeposit(
              memberId: 'm1',
              memberName: 'An',
              amount: 100000,
              emotionTag: '🔥',
              note: 'Thất bại không được lưu',
            ),
        throwsException,
      );
      expect(container.read(receiptApprovalProvider(tripId)).hasError, isTrue);
      expect(container.read(savingJournalProvider(params)), isEmpty);
    });
  });

  group('SavingPlanProvider Tests', () {
    test('createSavingPlan preserves existing paidAmount and completedInstallments when updating plan', () async {
      final repo = InMemorySavingRepository();
      const tripId = 'trip_plan_preserve';
      const memberId = 'm1';
      const params = SavingPlanParams(tripId: tripId, memberId: memberId);

      await repo.saveSavingPlan(
        SavingPlan(
          id: '${tripId}_$memberId',
          tripId: tripId,
          memberId: memberId,
          memberName: 'Đỗ Đình An',
          targetAmount: 2000000,
          paidAmount: 1484000,
          frequency: SavingFrequency.weekly,
          installmentAmount: 200000,
          totalInstallments: 10,
          completedInstallments: 7,
          startDate: DateTime(2026, 11, 1),
          deadlineDate: DateTime(2026, 12, 15),
        ),
      );

      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final updated = await container.read(savingPlanProvider(params).notifier).createSavingPlan(
            memberName: 'Đỗ Đình An',
            targetAmount: 2500000,
            startDate: DateTime(2026, 11, 27),
            deadlineDate: DateTime(2026, 12, 27),
            preferredFrequency: SavingFrequency.weekly,
          );

      expect(updated.paidAmount, 1484000);
      expect(updated.completedInstallments, 7);
      expect(updated.status, SavingPlanStatus.active);
    });
  });
}
