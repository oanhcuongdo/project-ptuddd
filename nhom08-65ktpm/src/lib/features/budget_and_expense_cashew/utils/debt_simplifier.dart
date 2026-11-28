/// Input contribution record for a member in a trip settlement calculation.
class MemberExpenseContribution {
  const MemberExpenseContribution({
    required this.memberId,
    required this.memberName,
    required this.paidAmount,
  });

  final String memberId;
  final String memberName;
  final int paidAmount;
}

/// Minimal peer-to-peer transfer produced by [DebtSimplifier].
class SimplifiedSettlement {
  const SimplifiedSettlement({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });

  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final int amount;
}

/// Debt-simplification calculator minimizing settlement transfers.
abstract final class DebtSimplifier {
  /// Splits total group expenses equally across [contributions] and computes
  /// the minimum transfers from net debtors to net creditors.
  static List<SimplifiedSettlement> simplifyEqualSplit(
    List<MemberExpenseContribution> contributions,
  ) {
    if (contributions.length <= 1) return const [];

    final totalPaid = contributions.fold<int>(
      0,
      (sum, c) => sum + c.paidAmount,
    );
    if (totalPaid <= 0) return const [];

    final count = contributions.length;
    final baseShare = totalPaid ~/ count;
    var remainder = totalPaid % count;

    final balances = <String, int>{};
    final names = <String, String>{};

    for (final c in contributions) {
      final share = baseShare + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      balances[c.memberId] = (balances[c.memberId] ?? 0) + c.paidAmount - share;
      names[c.memberId] = c.memberName;
    }

    return simplifyNetBalances(balances: balances, names: names);
  }

  /// Simplifies [balances] (positive = creditor, negative = debtor).
  ///
  /// Searches pairings for balanced member ledgers and uses a greedy fallback
  /// when the supplied balances do not sum to zero.
  static List<SimplifiedSettlement> simplifyNetBalances({
    required Map<String, int> balances,
    required Map<String, String> names,
  }) {
    final totalBalance = balances.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (totalBalance != 0) {
      return _greedySimplification(balances: balances, names: names);
    }

    final ids =
        balances.entries
            .where((entry) => entry.value != 0)
            .map((entry) => entry.key)
            .toList()
          ..sort((a, b) => balances[b]!.abs().compareTo(balances[a]!.abs()));
    if (ids.length <= 1) return const [];

    final remaining = [for (final id in ids) balances[id]!];
    final transfers = <SimplifiedSettlement>[];
    var best = _greedySimplification(balances: balances, names: names);

    void search(int start, int count) {
      while (start < remaining.length && remaining[start] == 0) {
        start++;
      }
      if (start == remaining.length) {
        if (count < best.length) {
          best = List<SimplifiedSettlement>.of(transfers);
        }
        return;
      }
      if (count >= best.length) return;

      final attemptedBalances = <int>{};
      for (var index = start + 1; index < remaining.length; index++) {
        final current = remaining[start];
        final candidate = remaining[index];
        if (candidate == 0 ||
            (current > 0) == (candidate > 0) ||
            !attemptedBalances.add(candidate)) {
          continue;
        }

        final amount = current.abs() < candidate.abs()
            ? current.abs()
            : candidate.abs();
        final debtorIndex = current < 0 ? start : index;
        final creditorIndex = current > 0 ? start : index;
        final debtorId = ids[debtorIndex];
        final creditorId = ids[creditorIndex];

        remaining[debtorIndex] += amount;
        remaining[creditorIndex] -= amount;
        transfers.add(
          SimplifiedSettlement(
            fromId: debtorId,
            fromName: names[debtorId] ?? debtorId,
            toId: creditorId,
            toName: names[creditorId] ?? creditorId,
            amount: amount,
          ),
        );
        search(start, count + 1);
        transfers.removeLast();
        remaining[debtorIndex] -= amount;
        remaining[creditorIndex] += amount;

        if (candidate.abs() == current.abs()) break;
      }
    }

    search(0, 0);
    return best;
  }

  static List<SimplifiedSettlement> _greedySimplification({
    required Map<String, int> balances,
    required Map<String, String> names,
  }) {
    final creditors = <MapEntry<String, int>>[];
    final debtors = <MapEntry<String, int>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors.add(entry);
      } else if (entry.value < 0) {
        debtors.add(MapEntry(entry.key, -entry.value));
      }
    }

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final transfers = <SimplifiedSettlement>[];
    var ci = 0;
    var di = 0;

    while (ci < creditors.length && di < debtors.length) {
      final creditor = creditors[ci];
      final debtor = debtors[di];
      final amount = creditor.value < debtor.value
          ? creditor.value
          : debtor.value;

      if (amount > 0) {
        transfers.add(
          SimplifiedSettlement(
            fromId: debtor.key,
            fromName: names[debtor.key] ?? debtor.key,
            toId: creditor.key,
            toName: names[creditor.key] ?? creditor.key,
            amount: amount,
          ),
        );
      }

      final remCreditor = creditor.value - amount;
      final remDebtor = debtor.value - amount;

      if (remCreditor == 0) {
        ci++;
      } else {
        creditors[ci] = MapEntry(creditor.key, remCreditor);
      }

      if (remDebtor == 0) {
        di++;
      } else {
        debtors[di] = MapEntry(debtor.key, remDebtor);
      }
    }

    return transfers;
  }
}
