import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/member_streak.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_plan_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_streak_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';

class _FailingStreakRepository extends InMemorySavingRepository {
  @override
  Future<void> updateMemberStreak(MemberStreak streak) async {
    throw Exception('Firestore write failed');
  }
}

void main() {
  group('MemberStreak journalEntries serialization', () {
    test('round-trips journalEntries through toMap and fromMap', () {
      final streak = MemberStreak(
        memberId: 'm1',
        tripId: 'trip_1',
        currentStreak: 3,
        longestStreak: 5,
        lastDepositDate: DateTime(2026, 11, 28),
        depositDates: const ['2026-11-26', '2026-11-27', '2026-11-28'],
        totalDisciplinedDays: 3,
        journalEntries: const {
          '2026-11-28': (emoji: '🔥', note: 'Góp quỹ đúng hạn'),
        },
      );

      final restored = MemberStreak.fromMap(
        streak.toMap(),
        memberId: streak.memberId,
        tripId: streak.tripId,
      );

      expect(restored.journalEntries.length, 1);
      expect(restored.journalEntries['2026-11-28']?.emoji, '🔥');
      expect(restored.journalEntries['2026-11-28']?.note, 'Góp quỹ đúng hạn');
    });

    test('defaults journalEntries to empty when absent in legacy Firestore docs', () {
      final restored = MemberStreak.fromMap(
        const {
          'currentStreak': 2,
          'longestStreak': 2,
          'depositDates': ['2026-11-27', '2026-11-28'],
        },
        memberId: 'm1',
        tripId: 'trip_1',
      );

      expect(restored.journalEntries, isEmpty);
      expect(restored.currentStreak, 2);
    });
  });

  group('SavingRepository trip & member sync', () {
    test('InMemorySavingRepository seeds and streams trip summary and members', () async {
      final repo = InMemorySavingRepository(seedDemo: true);

      final trip = await repo.watchTripSummary('trip_demo_01').first;
      final members = await repo.watchTripMembers('trip_demo_01').first;

      expect(trip, isNotNull);
      expect(trip!.hostId, 'member_demo_01');
      expect(members.length, 4);
      expect(members.first.userId, 'member_demo_01');
    });
  });

  group('SavingStreakNotifier journal persistence', () {
    test('checkIn persists journal entry into MemberStreak and updates local journal', () async {
      final repo = InMemorySavingRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const params = SavingPlanParams(tripId: 'trip_sync_1', memberId: 'm1');
      final date = DateTime(2026, 11, 28);

      final updated = await container.read(savingStreakProvider(params).notifier).checkIn(
            date: date,
            emoji: '🚀',
            note: '  Tiết kiệm cà phê  ',
          );

      expect(updated.journalEntries['2026-11-28']?.emoji, '🚀');
      expect(updated.journalEntries['2026-11-28']?.note, 'Tiết kiệm cà phê');

      final persisted = await repo.getMemberStreak('trip_sync_1', 'm1');
      expect(persisted.journalEntries['2026-11-28']?.emoji, '🚀');
      expect(
        container.read(savingJournalProvider(params))['2026-11-28']?.note,
        'Tiết kiệm cà phê',
      );
    });

    test('checkIn does not mutate savingJournalProvider when repository fails', () async {
      final repo = _FailingStreakRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const params = SavingPlanParams(tripId: 'trip_sync_err', memberId: 'm1');

      await expectLater(
        () => container.read(savingStreakProvider(params).notifier).checkIn(
              date: DateTime(2026, 11, 28),
              emoji: '🔥',
              note: 'Should not persist',
            ),
        throwsException,
      );

      expect(container.read(savingJournalProvider(params)), isEmpty);
    });
  });
}
