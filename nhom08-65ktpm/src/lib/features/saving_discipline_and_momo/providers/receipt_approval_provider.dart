import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../models/saving_plan.dart';
import '../repository/saving_repository_impl.dart';
import '../utils/saving_streak_calculator.dart';
import 'saving_plan_provider.dart';
import 'saving_streak_provider.dart';

/// Realtime stream of all [DepositRecord]s for a given [tripId].
final tripDepositsStreamProvider =
    StreamProvider.autoDispose.family<List<DepositRecord>, String>((ref, tripId) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchTripDeposits(tripId);
});

/// Realtime stream of pending [DepositRecord]s for a given [tripId].
final pendingDepositsStreamProvider =
    StreamProvider.autoDispose.family<List<DepositRecord>, String>((ref, tripId) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchPendingDeposits(tripId);
});

/// Realtime stream of all member [SavingPlan]s for a given [tripId].
final tripSavingPlansStreamProvider =
    StreamProvider.autoDispose.family<List<SavingPlan>, String>((ref, tripId) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchTripSavingPlans(tripId);
});

/// Realtime stream of all [MemberStreak]s for a given [tripId].
final tripStreaksStreamProvider =
    StreamProvider.autoDispose.family<List<MemberStreak>, String>((ref, tripId) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchTripStreaks(tripId);
});

/// Handles member receipt submission (with Firebase Storage upload)
/// and host approval / rejection transitions for a trip.
final receiptApprovalProvider =
    AsyncNotifierProvider.autoDispose.family<ReceiptApprovalNotifier, void, String>(
  ReceiptApprovalNotifier.new,
);

class ReceiptApprovalNotifier extends AsyncNotifier<void> {
  ReceiptApprovalNotifier(this._tripId);

  final String _tripId;

  @override
  Future<void> build() async {}

  /// Uploads optional [receiptImage] to Storage and creates a `PENDING` [DepositRecord].
  Future<DepositRecord> submitDeposit({
    required String memberId,
    required String memberName,
    required double amount,
    int installmentIndex = 0,
    DateTime? depositDate,
    DateTime? termDueDate,
    SavingFrequency? termFrequency,
    File? receiptImage,
    String? receiptImageUrl,
    String? note,
    String? emotionTag,
  }) async {
    final keepAliveLink = ref.keepAlive();
    try {
      final repository = ref.read(savingRepositoryProvider);
      final effectiveDate = depositDate ?? DateTime.now();
      final record = DepositRecord(
        id: 'dep_${DateTime.now().microsecondsSinceEpoch}_$memberId',
        tripId: _tripId,
        memberId: memberId,
        memberName: memberName,
        amount: amount,
        installmentIndex: installmentIndex,
        depositDate: effectiveDate,
        receiptImageUrl: receiptImageUrl,
        status: DepositStatus.pending,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        emotionTag: emotionTag,
        termDueDate: termDueDate,
        termFrequency: termFrequency,
      );

      state = const AsyncLoading();
      final result = await AsyncValue.guard(() async {
        await repository.submitDeposit(record, receiptImage: receiptImage);
        if (emotionTag != null && emotionTag.isNotEmpty) {
          ref
              .read(
                savingJournalProvider(
                  SavingPlanParams(tripId: _tripId, memberId: memberId),
                ).notifier,
              )
              .saveEntry(
                isoDate: SavingStreakCalculator.formatIsoDate(effectiveDate),
                emoji: emotionTag,
                note: note ?? '',
              );
        }
        return record;
      });

      if (!ref.mounted) {
        if (result.hasError) {
          Error.throwWithStackTrace(result.error!, result.stackTrace!);
        }
        return result.requireValue;
      }

      state = result.whenData((_) {});
      if (state.hasError) {
        Error.throwWithStackTrace(state.error!, state.stackTrace!);
      }
      return result.requireValue;
    } finally {
      keepAliveLink.close();
    }
  }

  /// Approves a pending deposit atomically (updating fund progress, plan, and streak).
  Future<void> approveDeposit({
    required String depositId,
    required String reviewerId,
  }) async {
    await _updateStatus(
      depositId: depositId,
      status: DepositStatus.approved,
      reviewerId: reviewerId,
    );
  }

  /// Rejects a pending deposit and records an optional [reason].
  Future<void> rejectDeposit({
    required String depositId,
    required String reviewerId,
    String? reason,
  }) async {
    await _updateStatus(
      depositId: depositId,
      status: DepositStatus.rejected,
      reviewerId: reviewerId,
      rejectionReason: reason,
    );
  }

  Future<void> _updateStatus({
    required String depositId,
    required DepositStatus status,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    final keepAliveLink = ref.keepAlive();
    try {
      final repository = ref.read(savingRepositoryProvider);
      state = const AsyncLoading();
      final result = await AsyncValue.guard(() async {
        await repository.updateDepositStatus(
          tripId: _tripId,
          depositId: depositId,
          status: status,
          reviewerId: reviewerId,
          rejectionReason: rejectionReason,
        );
      });

      if (!ref.mounted) {
        if (result.hasError) {
          Error.throwWithStackTrace(result.error!, result.stackTrace!);
        }
        return;
      }

      state = result;
      if (state.hasError) {
        Error.throwWithStackTrace(state.error!, state.stackTrace!);
      }
    } finally {
      keepAliveLink.close();
    }
  }
}
