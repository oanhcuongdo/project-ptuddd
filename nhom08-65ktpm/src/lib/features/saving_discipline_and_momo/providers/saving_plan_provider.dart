import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saving_plan.dart';
import '../repository/saving_repository_impl.dart';
import '../utils/saving_calculator.dart';

class SavingPlanParams {
  final String tripId;
  final String memberId;

  const SavingPlanParams({
    required this.tripId,
    required this.memberId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingPlanParams &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          memberId == other.memberId;

  @override
  int get hashCode => tripId.hashCode ^ memberId.hashCode;
}

final savingPlanProvider =
    AsyncNotifierProvider.autoDispose.family<SavingPlanNotifier, SavingPlan?, SavingPlanParams>(
  SavingPlanNotifier.new,
);

class SavingPlanNotifier
    extends AsyncNotifier<SavingPlan?> {
  final SavingPlanParams _params;

  SavingPlanNotifier(this._params);

  @override
  Future<SavingPlan?> build() async {
    final repository = ref.watch(savingRepositoryProvider);
    return await repository.getSavingPlan(_params.tripId, _params.memberId);
  }

  /// Automatically generates and saves a saving plan using [SavingCalculator]
  Future<SavingPlan> createSavingPlan({
    required String memberName,
    required double targetAmount,
    required DateTime startDate,
    required DateTime deadlineDate,
    SavingFrequency preferredFrequency = SavingFrequency.weekly,
  }) async {
    state = const AsyncLoading();
    late SavingPlan createdPlan;

    state = await AsyncValue.guard(() async {
      final repository = ref.read(savingRepositoryProvider);
      final existing =
          state.value ?? await repository.getSavingPlan(_params.tripId, _params.memberId);
      final existingPaid = existing?.paidAmount ?? 0.0;
      final existingCompleted = existing?.completedInstallments ?? 0;

      final calcResult = SavingCalculator.calculateInstallments(
        targetAmount: targetAmount,
        startDate: startDate,
        deadlineDate: deadlineDate,
        preferredFrequency: preferredFrequency,
        alreadyPaidAmount: existingPaid,
      );

      final plan = SavingPlan(
        id: '${_params.tripId}_${_params.memberId}',
        tripId: _params.tripId,
        memberId: _params.memberId,
        memberName: memberName,
        targetAmount: targetAmount,
        paidAmount: existingPaid,
        frequency: calcResult.frequency,
        installmentAmount: calcResult.installmentAmount,
        totalInstallments: calcResult.totalInstallments,
        completedInstallments: existingCompleted,
        startDate: startDate,
        deadlineDate: deadlineDate,
        status: existingPaid >= targetAmount
            ? SavingPlanStatus.completed
            : SavingPlanStatus.active,
      );

      await repository.saveSavingPlan(plan);
      createdPlan = plan;
      return plan;
    });

    return createdPlan;
  }
}
