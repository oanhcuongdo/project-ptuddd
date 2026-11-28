import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../repository/saving_repository_impl.dart';
import '../utils/saving_streak_calculator.dart';
import 'saving_plan_provider.dart';

/// Realtime stream of [MemberStreak] for a given (tripId, memberId).
final savingStreakStreamProvider =
    StreamProvider.autoDispose.family<MemberStreak, SavingPlanParams>((ref, params) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchMemberStreak(params.tripId, params.memberId);
});

/// Realtime stream of member [DepositRecord]s for a given (tripId, memberId).
final memberDepositsStreamProvider =
    StreamProvider.autoDispose.family<List<DepositRecord>, SavingPlanParams>((ref, params) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchMemberDeposits(params.tripId, params.memberId);
});

/// Stores DailyYou emotion emojis and short journal notes keyed by ISO date (`YYYY-MM-DD`).
final savingJournalProvider = NotifierProvider.family<
    SavingJournalNotifier,
    Map<String, ({String emoji, String note})>,
    SavingPlanParams>(
  SavingJournalNotifier.new,
);

class SavingJournalNotifier
    extends Notifier<Map<String, ({String emoji, String note})>> {
  SavingJournalNotifier(this._params);

  // Kept for scoped family isolation per trip/member.
  // ignore: unused_field
  final SavingPlanParams _params;

  @override
  Map<String, ({String emoji, String note})> build() => const {};

  void saveEntry({
    required String isoDate,
    required String emoji,
    required String note,
  }) {
    state = {
      ...state,
      isoDate: (emoji: emoji, note: note.trim()),
    };
  }
}

/// Manages saving streak check-ins and persistence via [SavingRepository].
final savingStreakProvider = AsyncNotifierProvider.autoDispose
    .family<SavingStreakNotifier, MemberStreak, SavingPlanParams>(
  SavingStreakNotifier.new,
);

class SavingStreakNotifier extends AsyncNotifier<MemberStreak> {
  final SavingPlanParams _params;

  SavingStreakNotifier(this._params);

  @override
  Future<MemberStreak> build() async {
    final repository = ref.watch(savingRepositoryProvider);
    return repository.getMemberStreak(_params.tripId, _params.memberId);
  }

  /// Checks in a saving day and saves the associated DailyYou emotion & journal note.
  Future<MemberStreak> checkIn({
    required DateTime date,
    required String emoji,
    required String note,
  }) async {
    final keepAliveLink = ref.keepAlive();
    try {
      final repository = ref.read(savingRepositoryProvider);
      final current =
          state.value ?? await repository.getMemberStreak(_params.tripId, _params.memberId);

      state = const AsyncLoading();
      final iso = SavingStreakCalculator.formatIsoDate(date);
      final result = await AsyncValue.guard(() async {
        final computed = SavingStreakCalculator.recordCheckIn(
          current,
          date,
          referenceDate: DateTime.now(),
        );
        final updated = computed.copyWith(
          journalEntries: {
            ...computed.journalEntries,
            iso: (emoji: emoji, note: note.trim()),
          },
        );
        await repository.updateMemberStreak(updated);
        return updated;
      });

      if (!result.hasError) {
        ref.read(savingJournalProvider(_params).notifier).saveEntry(
              isoDate: iso,
              emoji: emoji,
              note: note,
            );
      }

      if (!ref.mounted) {
        if (result.hasError) {
          Error.throwWithStackTrace(result.error!, result.stackTrace!);
        }
        return result.requireValue;
      }

      state = result;
      if (state.hasError) {
        Error.throwWithStackTrace(state.error!, state.stackTrace!);
      }
      return state.requireValue;
    } finally {
      keepAliveLink.close();
    }
  }
}
