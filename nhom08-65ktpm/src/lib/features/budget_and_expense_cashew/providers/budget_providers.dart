import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_envelope.dart';
import '../models/trip_expense.dart';
import '../repository/budget_repository.dart';

class BudgetStreamParams {
  const BudgetStreamParams({
    required this.tripId,
    required this.targetBudget,
    required this.isHost,
  });

  final String tripId;
  final int targetBudget;
  final bool isHost;

  @override
  bool operator ==(Object other) =>
      other is BudgetStreamParams &&
      other.tripId == tripId &&
      other.targetBudget == targetBudget &&
      other.isHost == isHost;

  @override
  int get hashCode => Object.hash(tripId, targetBudget, isHost);
}

final budgetEnvelopeStreamProvider = StreamProvider.autoDispose
    .family<List<BudgetEnvelope>, BudgetStreamParams>((ref, params) {
      return ref
          .watch(budgetRepositoryProvider)
          .watchEnvelopes(
            params.tripId,
            targetBudget: params.targetBudget,
            initializeDefaults: params.isHost,
          );
    });

final budgetExpenseStreamProvider = StreamProvider.autoDispose
    .family<List<TripExpense>, BudgetStreamParams>((ref, params) {
      return ref
          .watch(budgetRepositoryProvider)
          .watchExpenses(params.tripId, targetBudget: params.targetBudget);
    });

final budgetControllerProvider = Provider<BudgetController>((ref) {
  return BudgetController(ref.watch(budgetRepositoryProvider));
});

class BudgetController {
  const BudgetController(this._repository);

  final BudgetRepository _repository;

  Future<TripExpense> addExpense({
    required String tripId,
    required TripExpense expense,
  }) {
    return _repository.addExpense(tripId: tripId, expense: expense);
  }

  Future<void> updateEnvelopeBudget({
    required String tripId,
    required String envelopeId,
    required int allocatedAmount,
  }) {
    return _repository.updateEnvelopeBudget(
      tripId: tripId,
      envelopeId: envelopeId,
      allocatedAmount: allocatedAmount,
    );
  }
}

int collectedAmountForEnvelope({
  required BudgetEnvelope envelope,
  required List<BudgetEnvelope> envelopes,
  required int totalCollected,
}) {
  final totalAllocated = envelopes.fold<int>(
    0,
    (total, item) => total + item.allocatedAmount,
  );
  if (totalAllocated == 0) return 0;
  final index = envelopes.indexWhere((item) => item.id == envelope.id);
  if (index == -1) return 0;
  final shares = envelopes
      .map((item) => totalCollected * item.allocatedAmount ~/ totalAllocated)
      .toList();
  var remaining = totalCollected - shares.fold<int>(0, (a, b) => a + b);
  for (var i = 0; i < shares.length && remaining > 0; i++) {
    shares[i]++;
    remaining--;
  }
  return shares[index];
}
