import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/core/services/local_notification_service.dart';
import 'package:travel_buddy/features/goal_and_checklist/data/smart_templates.dart';
import 'package:travel_buddy/features/goal_and_checklist/models/checklist_item.dart';
import 'package:travel_buddy/features/goal_and_checklist/presentation/checklist_screen.dart';
import 'package:travel_buddy/features/goal_and_checklist/repository/checklist_repository.dart';
import 'package:travel_buddy/features/goal_and_checklist/utils/checklist_reminder_helper.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/saving_plan.dart';
import 'package:travel_buddy/models/trip_model.dart';

void main() {
  group('ChecklistReminderHelper Tests', () {
    test('computes readiness progress, overdue, and dueSoon items accurately', () {
      final now = DateTime(2026, 11, 27, 10, 0);
      final items = [
        ChecklistItem(
          id: '1',
          tripId: 't1',
          title: 'Xong',
          isCompleted: true,
          dueDate: DateTime(2026, 11, 25),
          createdBy: 'u1',
          createdAt: now,
        ),
        ChecklistItem(
          id: '2',
          tripId: 't1',
          title: 'Quá hạn',
          isCompleted: false,
          dueDate: DateTime(2026, 11, 26),
          createdBy: 'u1',
          createdAt: now,
        ),
        ChecklistItem(
          id: '3',
          tripId: 't1',
          title: 'Sắp đến hạn',
          isCompleted: false,
          dueDate: DateTime(2026, 11, 28),
          createdBy: 'u1',
          createdAt: now,
        ),
        ChecklistItem(
          id: '4',
          tripId: 't1',
          title: 'Còn xa',
          isCompleted: false,
          dueDate: DateTime(2026, 12, 10),
          createdBy: 'u1',
          createdAt: now,
        ),
      ];

      final stats = ChecklistReminderHelper.computeReadiness(items, now: now);
      expect(stats.totalCount, 4);
      expect(stats.completedCount, 1);
      expect(stats.percent, 25);
      expect(stats.overdueItems.map((e) => e.id), ['2']);
      expect(stats.dueSoonItems.map((e) => e.id), ['3']);
      expect(stats.hasUrgentReminders, isTrue);
      expect(
        ChecklistReminderHelper.buildReminderMessage(stats),
        contains('1 việc quá hạn và 1 việc sắp đến hạn'),
      );
    });

    test('groups timeline phases in chronological order and packing by scope', () {
      final now = DateTime(2026, 11, 27);
      final items = [
        ChecklistItem(
          id: 'p1',
          tripId: 't1',
          title: 'Đồ cá nhân',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.personal,
          createdBy: 'u1',
          createdAt: now,
        ),
        ChecklistItem(
          id: 't3',
          tripId: 't1',
          title: 'Chốt cuối',
          phase: ChecklistPhase.before3d,
          createdBy: 'u1',
          createdAt: now,
        ),
        ChecklistItem(
          id: 't1',
          tripId: 't1',
          title: 'Đặt vé',
          phase: ChecklistPhase.before30d,
          createdBy: 'u1',
          createdAt: now,
        ),
        ChecklistItem(
          id: 'p2',
          tripId: 't1',
          title: 'Đồ nhóm',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.group,
          createdBy: 'u1',
          createdAt: now,
        ),
      ];

      final timeline = ChecklistReminderHelper.groupTimelineByPhase(items);
      expect(
        timeline.keys.toList(),
        [ChecklistPhase.before30d.label, ChecklistPhase.before3d.label],
      );

      final packing = ChecklistReminderHelper.groupPackingByScope(items);
      expect(
        packing.keys.toList(),
        ['Đồ dùng chung của nhóm', 'Hành lý cá nhân của bạn'],
      );
    });
  });

  group('InMemoryChecklistRepository Tests', () {
    test('applies smart templates without duplicating existing titles', () async {
      final repo = InMemoryChecklistRepository(seedDemo: false);
      final now = DateTime(2026, 11, 27);
      final trip = TripModel(
        id: 'trip-beach',
        title: 'Phú Quốc',
        destination: 'Phú Quốc',
        startDate: now.add(const Duration(days: 35)),
        endDate: now.add(const Duration(days: 38)),
        hostId: 'u1',
        inviteCode: 'PQ2026',
        createdAt: now,
        updatedAt: now,
      );

      final beachTemplate = SmartChecklistTemplates.all.first;
      final addedFirst = await repo.applyTemplate(
        trip: trip,
        template: beachTemplate,
        createdBy: 'u1',
      );
      expect(addedFirst, beachTemplate.items.length);

      final addedSecond = await repo.applyTemplate(
        trip: trip,
        template: beachTemplate,
        createdBy: 'u1',
      );
      expect(addedSecond, 0);
    });

    test('toggles completion, assigns member, and attaches proof photo', () async {
      final repo = InMemoryChecklistRepository(seedDemo: false);
      final now = DateTime.now();
      final item = await repo.addItem(
        ChecklistItem(
          id: '',
          tripId: 't-new',
          title: 'Mua vé tham quan',
          phase: ChecklistPhase.before14d,
          createdBy: 'u1',
          createdAt: now,
        ),
      );

      await repo.assignMember(
        item: item,
        assigneeId: 'u2',
        assigneeName: 'Nguyễn Xuân Bình',
      );
      final updated = await repo.attachProofPhoto(
        item: item,
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        completedBy: 'u2',
      );

      expect(updated.isCompleted, isTrue);
      expect(updated.hasProofPhoto, isTrue);
      expect(updated.proofImageUrl, contains('checklists/${item.id}/'));
    });
  });

  group('ChecklistScreen Widget Tests', () {
    testWidgets('renders countdown, readiness rings, and switches tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChecklistScreen(tripId: 'demo-trip'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đà Lạt 4N3Đ'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget); // 3 of 6 seeded items done
      expect(find.text('Đặt vé xe giường nằm khứ hồi'), findsOneWidget);

      await tester.tap(find.text('Hành lý & Đồ chung'));
      await tester.pumpAndSettle();

      expect(find.text('ĐỒ DÙNG CHUNG CỦA NHÓM'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('HÀNH LÝ CÁ NHÂN CỦA BẠN'),
        150,
      );
      expect(find.text('HÀNH LÝ CÁ NHÂN CỦA BẠN'), findsOneWidget);
    });
  });

  group('LocalNotificationService & TripType Template Mapping Tests', () {
    test('computes deterministic notification ids and reminder timestamps', () {
      final now = DateTime(2026, 11, 27, 10, 0);
      final futureItem = ChecklistItem(
        id: 'chk-future',
        tripId: 't1',
        title: 'Đặt vé máy bay',
        dueDate: DateTime(2026, 11, 30),
        createdBy: 'u1',
        createdAt: now,
      );
      final doneItem = futureItem.copyWith(id: 'chk-done', isCompleted: true);

      expect(
        LocalNotificationService.computeReminderScheduleTime(futureItem, now: now),
        DateTime(2026, 11, 29, 9, 0),
      );
      expect(
        LocalNotificationService.computeReminderScheduleTime(doneItem, now: now),
        isNull,
      );
      expect(
        LocalNotificationService.notificationIdForItem('chk-future'),
        greaterThan(0),
      );
    });

    test('maps TripType to matching SmartChecklistTemplate', () {
      expect(SmartChecklistTemplates.forTripType(TripType.beach)?.id, 'tpl_beach');
      expect(SmartChecklistTemplates.forTripType(TripType.trekking)?.id, 'tpl_trekking');
      expect(SmartChecklistTemplates.forTripType(TripType.motorbike)?.id, 'tpl_motorbike');
      expect(SmartChecklistTemplates.forTripType(TripType.backpacking)?.id, 'tpl_backpacking');
      expect(SmartChecklistTemplates.forTripType(TripType.other), isNull);
    });

    test('computes saving reminder schedule time for active vs completed plans', () {
      final now = DateTime(2026, 11, 1, 8, 0);
      final plan = SavingPlan(
        id: 't1_u1',
        tripId: 't1',
        memberId: 'u1',
        memberName: 'An',
        targetAmount: 1000000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 250000,
        totalInstallments: 4,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 29),
      );
      final scheduled = LocalNotificationService.computeSavingReminderScheduleTime(
        plan: plan,
        deposits: const [],
        now: now,
      );
      expect(scheduled, DateTime(2026, 11, 8, 9, 0));

      final completedPlan = plan.copyWith(
        paidAmount: 1000000,
        status: SavingPlanStatus.completed,
      );
      expect(
        LocalNotificationService.computeSavingReminderScheduleTime(
          plan: completedPlan,
          deposits: const [],
          now: now,
        ),
        isNull,
      );
    });
  });
}
