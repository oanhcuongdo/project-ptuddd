import 'dart:async';
import 'dart:io';

import '../../../models/trip_member.dart';
import '../../../models/trip_model.dart';
import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../utils/saving_streak_calculator.dart';
import 'saving_repository.dart';

/// In-memory [SavingRepository] fallback used when Firebase is not initialized
/// (e.g., `main_ui_preview.dart` or isolated widget/unit tests).
class InMemorySavingRepository implements SavingRepository {
  InMemorySavingRepository({bool seedDemo = false}) {
    if (seedDemo) {
      _seedDemoTrip('trip_demo_01');
    }
  }

  final Map<String, TripModel> _trips = {};
  final Map<String, StreamController<TripModel?>> _tripControllers = {};

  final Map<String, List<TripMember>> _tripMembers = {};
  final Map<String, StreamController<List<TripMember>>> _tripMembersControllers = {};

  final Map<String, MoMoFundConfig> _fundConfigs = {};
  final Map<String, StreamController<MoMoFundConfig?>> _fundControllers = {};

  final Map<String, SavingPlan> _savingPlans = {};
  final Map<String, StreamController<SavingPlan?>> _planControllers = {};
  final Map<String, StreamController<List<SavingPlan>>> _tripPlansControllers = {};

  final Map<String, List<DepositRecord>> _deposits = {};
  final Map<String, StreamController<List<DepositRecord>>> _depositControllers = {};

  final Map<String, MemberStreak> _streaks = {};
  final Map<String, StreamController<MemberStreak>> _streakControllers = {};
  final Map<String, StreamController<List<MemberStreak>>> _tripStreaksControllers = {};

  StreamController<MoMoFundConfig?> _fundController(String tripId) =>
      _fundControllers.putIfAbsent(tripId, () => StreamController<MoMoFundConfig?>.broadcast());

  StreamController<TripModel?> _tripController(String tripId) =>
      _tripControllers.putIfAbsent(tripId, () => StreamController<TripModel?>.broadcast());

  StreamController<List<TripMember>> _tripMembersController(String tripId) =>
      _tripMembersControllers.putIfAbsent(
        tripId,
        () => StreamController<List<TripMember>>.broadcast(),
      );

  StreamController<SavingPlan?> _planController(String key) =>
      _planControllers.putIfAbsent(key, () => StreamController<SavingPlan?>.broadcast());

  StreamController<List<SavingPlan>> _tripPlansController(String tripId) =>
      _tripPlansControllers.putIfAbsent(
        tripId,
        () => StreamController<List<SavingPlan>>.broadcast(),
      );

  StreamController<List<DepositRecord>> _depositController(String tripId) =>
      _depositControllers.putIfAbsent(tripId, () => StreamController<List<DepositRecord>>.broadcast());

  StreamController<MemberStreak> _streakController(String key) =>
      _streakControllers.putIfAbsent(key, () => StreamController<MemberStreak>.broadcast());

  StreamController<List<MemberStreak>> _tripStreaksController(String tripId) =>
      _tripStreaksControllers.putIfAbsent(
        tripId,
        () => StreamController<List<MemberStreak>>.broadcast(),
      );

  List<SavingPlan> _plansForTrip(String tripId) =>
      _savingPlans.values.where((p) => p.tripId == tripId).toList();

  List<MemberStreak> _streaksForTrip(String tripId) =>
      _streaks.values.where((s) => s.tripId == tripId).toList();

  List<DepositRecord> _sortedDepositsForTrip(String tripId) {
    final list = List<DepositRecord>.from(_deposits[tripId] ?? const []);
    list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
    return List.unmodifiable(list);
  }

  void _seedDemoTrip(String tripId) {
    final now = DateTime.now();
    _fundConfigs[tripId] = MoMoFundConfig(
      tripId: tripId,
      fundName: 'Quỹ Đà Lạt 4N3Đ - Nhóm 8',
      hostUserId: 'member_demo_01',
      hostName: 'Đỗ Đình An',
      momoPhoneNumber: '0912345678',
      momoFundDeeplink: 'https://me.momo.vn/quy-nhom-dl-g8',
      qrCodeUrl: 'https://me.momo.vn/quy-nhom-dl-g8',
      targetTotalAmount: 8450000,
      currentCollectedAmount: 5070000,
      updatedAt: now,
    );

    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 35));
    final deadline = DateTime(now.year, now.month, now.day).add(const Duration(days: 35));

    final demoPlans = [
      SavingPlan(
        id: '${tripId}_member_demo_01',
        tripId: tripId,
        memberId: 'member_demo_01',
        memberName: 'Đỗ Đình An',
        targetAmount: 2112500,
        paidAmount: 1484000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 212000,
        totalInstallments: 10,
        completedInstallments: 7,
        startDate: start,
        deadlineDate: deadline,
      ),
      SavingPlan(
        id: '${tripId}_m2',
        tripId: tripId,
        memberId: 'm2',
        memberName: 'Nguyễn Xuân Bình',
        targetAmount: 2112500,
        paidAmount: 1272000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 212000,
        totalInstallments: 10,
        completedInstallments: 6,
        startDate: start,
        deadlineDate: deadline,
      ),
      SavingPlan(
        id: '${tripId}_m3',
        tripId: tripId,
        memberId: 'm3',
        memberName: 'Đỗ Tùng Khánh',
        targetAmount: 2112500,
        paidAmount: 1272000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 212000,
        totalInstallments: 10,
        completedInstallments: 6,
        startDate: start,
        deadlineDate: deadline,
      ),
      SavingPlan(
        id: '${tripId}_m4',
        tripId: tripId,
        memberId: 'm4',
        memberName: 'Hồ Thế Dũng',
        targetAmount: 2112500,
        paidAmount: 1042000,
        frequency: SavingFrequency.weekly,
        installmentAmount: 212000,
        totalInstallments: 10,
        completedInstallments: 5,
        startDate: start,
        deadlineDate: deadline,
      ),
    ];
    for (final plan in demoPlans) {
      _savingPlans['${tripId}_${plan.memberId}'] = plan;
    }

    _trips[tripId] = TripModel(
      id: tripId,
      title: 'Đà Lạt 4N3Đ - Nhóm 8',
      destination: 'Đà Lạt',
      startDate: deadline,
      endDate: deadline.add(const Duration(days: 3)),
      hostId: 'member_demo_01',
      memberIds: demoPlans.map((p) => p.memberId).toList(),
      inviteCode: 'TBDL08',
      targetBudget: 8450000,
      perMemberTarget: 2112500,
      totalSavedAmount: 5070000,
      createdAt: start,
      updatedAt: now,
    );

    _tripMembers[tripId] = [
      for (var i = 0; i < demoPlans.length; i++)
        TripMember(
          userId: demoPlans[i].memberId,
          displayName: demoPlans[i].memberName,
          role: i == 0 ? TripRole.host : TripRole.member,
          targetContribution: demoPlans[i].targetAmount.round(),
          contributedAmount: demoPlans[i].paidAmount.round(),
          currentStreak: i == 0 ? 6 : (i == 3 ? 4 : 5),
          joinedAt: start.add(Duration(minutes: i)),
        ),
    ];

    String isoDaysAgo(int days) =>
        SavingStreakCalculator.formatIsoDate(now.subtract(Duration(days: days)));

    _streaks['${tripId}_member_demo_01'] = MemberStreak(
      memberId: 'member_demo_01',
      tripId: tripId,
      currentStreak: 6,
      longestStreak: 6,
      lastDepositDate: now.subtract(const Duration(days: 1)),
      depositDates: List.generate(6, (i) => isoDaysAgo(6 - i)),
      totalDisciplinedDays: 6,
    );
    _streaks['${tripId}_m2'] = MemberStreak(
      memberId: 'm2',
      tripId: tripId,
      currentStreak: 5,
      longestStreak: 5,
      lastDepositDate: now.subtract(const Duration(days: 1)),
      depositDates: List.generate(5, (i) => isoDaysAgo(5 - i)),
      totalDisciplinedDays: 5,
    );
    _streaks['${tripId}_m3'] = MemberStreak(
      memberId: 'm3',
      tripId: tripId,
      currentStreak: 5,
      longestStreak: 5,
      lastDepositDate: now.subtract(const Duration(days: 1)),
      depositDates: List.generate(5, (i) => isoDaysAgo(5 - i)),
      totalDisciplinedDays: 5,
    );
    _streaks['${tripId}_m4'] = MemberStreak(
      memberId: 'm4',
      tripId: tripId,
      currentStreak: 4,
      longestStreak: 4,
      lastDepositDate: now.subtract(const Duration(days: 2)),
      depositDates: List.generate(4, (i) => isoDaysAgo(5 - i)),
      totalDisciplinedDays: 4,
    );

    _deposits[tripId] = [
      DepositRecord(
        id: 'r1',
        tripId: tripId,
        memberId: 'm2',
        memberName: 'Nguyễn Xuân Bình',
        amount: 212000,
        installmentIndex: 6,
        depositDate: now.subtract(const Duration(minutes: 45)),
        termDueDate: start.add(const Duration(days: 42)),
        termFrequency: SavingFrequency.weekly,
        emotionTag: '🔥',
        note: 'Nhịn 2 ly trà sữa góp quỹ đúng hạn!',
        status: DepositStatus.pending,
      ),
      DepositRecord(
        id: 'r2',
        tripId: tripId,
        memberId: 'm3',
        memberName: 'Đỗ Tùng Khánh',
        amount: 212000,
        installmentIndex: 6,
        depositDate: now.subtract(const Duration(hours: 2)),
        termDueDate: start.add(const Duration(days: 42)),
        termFrequency: SavingFrequency.weekly,
        emotionTag: '😎',
        note: 'Đã nạp đủ kỳ 6 qua Quỹ nhóm MoMo',
        status: DepositStatus.pending,
      ),
      DepositRecord(
        id: 'r3_t1',
        tripId: tripId,
        memberId: 'member_demo_01',
        memberName: 'Đỗ Đình An',
        amount: 212000,
        installmentIndex: 1,
        depositDate: start.add(const Duration(days: 6)),
        termDueDate: start.add(const Duration(days: 7)),
        termFrequency: SavingFrequency.weekly,
        emotionTag: '🚀',
        note: 'Hoàn thành kỳ 1 đúng hạn',
        status: DepositStatus.approved,
        approvedBy: 'member_demo_01',
        approvedAt: start.add(const Duration(days: 6)),
      ),
      DepositRecord(
        id: 'r3_t2',
        tripId: tripId,
        memberId: 'member_demo_01',
        memberName: 'Đỗ Đình An',
        amount: 212000,
        installmentIndex: 2,
        depositDate: start.add(const Duration(days: 13)),
        termDueDate: start.add(const Duration(days: 14)),
        termFrequency: SavingFrequency.weekly,
        emotionTag: '😎',
        note: 'Hoàn thành kỳ 2 đúng hạn',
        status: DepositStatus.approved,
        approvedBy: 'member_demo_01',
        approvedAt: start.add(const Duration(days: 13)),
      ),
      DepositRecord(
        id: 'r3_t3',
        tripId: tripId,
        memberId: 'member_demo_01',
        memberName: 'Đỗ Đình An',
        amount: 212000,
        installmentIndex: 3,
        depositDate: start.add(const Duration(days: 20)),
        termDueDate: start.add(const Duration(days: 21)),
        termFrequency: SavingFrequency.weekly,
        emotionTag: '💪',
        note: 'Hoàn thành kỳ 3 đúng hạn',
        status: DepositStatus.approved,
        approvedBy: 'member_demo_01',
        approvedAt: start.add(const Duration(days: 20)),
      ),
      DepositRecord(
        id: 'r3_t4',
        tripId: tripId,
        memberId: 'member_demo_01',
        memberName: 'Đỗ Đình An',
        amount: 212000,
        installmentIndex: 4,
        depositDate: start.add(const Duration(days: 27)),
        termDueDate: start.add(const Duration(days: 28)),
        termFrequency: SavingFrequency.weekly,
        emotionTag: '🔥',
        note: 'Hoàn thành kỳ 4 đúng hạn',
        status: DepositStatus.approved,
        approvedBy: 'member_demo_01',
        approvedAt: start.add(const Duration(days: 27)),
      ),
      DepositRecord(
        id: 'r3',
        tripId: tripId,
        memberId: 'member_demo_01',
        memberName: 'Đỗ Đình An',
        amount: 212000,
        installmentIndex: 5,
        depositDate: now.subtract(const Duration(days: 1)),
        termDueDate: start.add(const Duration(days: 35)),
        termFrequency: SavingFrequency.weekly,
        emotionTag: '🚀',
        note: 'Trưởng nhóm gương mẫu chốt sớm',
        status: DepositStatus.approved,
        approvedBy: 'member_demo_01',
        approvedAt: now.subtract(const Duration(hours: 20)),
      ),
    ];
  }

  void seedTripSummary(TripModel trip) {
    _trips[trip.id] = trip;
    _tripController(trip.id).add(trip);
  }

  void seedTripMembers(String tripId, List<TripMember> members) {
    _tripMembers[tripId] = List<TripMember>.from(members);
    _tripMembersController(tripId).add(List.unmodifiable(_tripMembers[tripId]!));
  }

  @override
  Stream<TripModel?> watchTripSummary(String tripId) async* {
    yield _trips[tripId];
    yield* _tripController(tripId).stream;
  }

  @override
  Stream<List<TripMember>> watchTripMembers(String tripId) async* {
    yield List.unmodifiable(_tripMembers[tripId] ?? const <TripMember>[]);
    yield* _tripMembersController(tripId).stream;
  }

  @override
  Future<MoMoFundConfig?> getFundConfig(String tripId) async => _fundConfigs[tripId];

  @override
  Stream<MoMoFundConfig?> watchFundConfig(String tripId) async* {
    yield _fundConfigs[tripId];
    yield* _fundController(tripId).stream;
  }

  @override
  Future<void> saveFundConfig(MoMoFundConfig config) async {
    final members = _tripMembers[config.tripId];
    final memberCount = members?.length ?? 0;
    final effectiveConfig = (memberCount > 0 &&
            config.targetTotalAmount > 0 &&
            config.suggestedPerMemberAmount != null)
        ? config.copyWith(
            suggestedPerMemberAmount: MoMoFundConfig.computeSuggestedPerMemberAmount(
              targetTotalAmount: config.targetTotalAmount,
              memberCount: memberCount,
              frequency: config.defaultFrequency,
            ),
          )
        : config;

    _fundConfigs[effectiveConfig.tripId] = effectiveConfig;
    _fundController(effectiveConfig.tripId).add(effectiveConfig);

    final perMemberTotal = (memberCount > 0 && effectiveConfig.targetTotalAmount > 0)
        ? (effectiveConfig.targetTotalAmount / memberCount).round()
        : 0;

    if (perMemberTotal > 0 && members != null) {
      for (var i = 0; i < members.length; i++) {
        members[i] = members[i].copyWith(targetContribution: perMemberTotal);
      }
      _tripMembersController(effectiveConfig.tripId)
          .add(List.unmodifiable(members));
    }

    final tripPlans = _plansForTrip(effectiveConfig.tripId);
    if (tripPlans.isNotEmpty) {
      for (final plan in tripPlans) {
        final updatedPlan = MoMoFundConfig.applyGroupConfigToPlan(
          plan: plan,
          perMemberTotalTarget:
              perMemberTotal > 0 ? perMemberTotal.toDouble() : plan.targetAmount,
          defaultFrequency: effectiveConfig.defaultFrequency,
        );
        final key = '${plan.tripId}_${plan.memberId}';
        _savingPlans[key] = updatedPlan;
        _planController(key).add(updatedPlan);
      }
      _tripPlansController(effectiveConfig.tripId)
          .add(List.unmodifiable(_plansForTrip(effectiveConfig.tripId)));
    }
  }

  @override
  Future<SavingPlan?> getSavingPlan(String tripId, String memberId) async =>
      _savingPlans['${tripId}_$memberId'];

  @override
  Stream<SavingPlan?> watchSavingPlan(String tripId, String memberId) async* {
    final key = '${tripId}_$memberId';
    yield _savingPlans[key];
    yield* _planController(key).stream;
  }

  @override
  Stream<List<SavingPlan>> watchTripSavingPlans(String tripId) async* {
    yield List.unmodifiable(_plansForTrip(tripId));
    yield* _tripPlansController(tripId).stream;
  }

  @override
  Future<void> saveSavingPlan(SavingPlan plan) async {
    final key = '${plan.tripId}_${plan.memberId}';
    _savingPlans[key] = plan;
    _planController(key).add(plan);
    _tripPlansController(plan.tripId).add(List.unmodifiable(_plansForTrip(plan.tripId)));
  }

  @override
  Future<void> submitDeposit(DepositRecord record, {File? receiptImage}) async {
    final list = _deposits.putIfAbsent(record.tripId, () => []);
    list.add(record.copyWith(receiptImageUrl: receiptImage?.path ?? record.receiptImageUrl));
    _depositController(record.tripId).add(_sortedDepositsForTrip(record.tripId));
  }

  @override
  Future<List<DepositRecord>> getPendingDeposits(String tripId) async {
    return _sortedDepositsForTrip(tripId)
        .where((d) => d.status == DepositStatus.pending)
        .toList();
  }

  @override
  Stream<List<DepositRecord>> watchPendingDeposits(String tripId) async* {
    yield await getPendingDeposits(tripId);
    yield* _depositController(tripId).stream.map(
          (list) => list.where((d) => d.status == DepositStatus.pending).toList(),
        );
  }

  @override
  Stream<List<DepositRecord>> watchTripDeposits(String tripId) async* {
    yield _sortedDepositsForTrip(tripId);
    yield* _depositController(tripId).stream;
  }

  @override
  Stream<List<DepositRecord>> watchMemberDeposits(String tripId, String memberId) async* {
    yield _sortedDepositsForTrip(tripId).where((d) => d.memberId == memberId).toList();
    yield* _depositController(tripId).stream.map(
          (list) => list.where((d) => d.memberId == memberId).toList(),
        );
  }

  @override
  Future<void> updateDepositStatus({
    required String tripId,
    required String depositId,
    required DepositStatus status,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    final list = _deposits[tripId] ?? [];
    final idx = list.indexWhere((d) => d.id == depositId);
    if (idx == -1) {
      throw Exception('Deposit record $depositId not found.');
    }

    final existingDeposit = list[idx];
    final isTransitionToApproved =
        status == DepositStatus.approved && existingDeposit.status != DepositStatus.approved;
    final trimmedReason = rejectionReason?.trim();

    list[idx] = existingDeposit.copyWith(
      status: status,
      approvedBy: reviewerId,
      approvedAt: DateTime.now(),
      rejectionReason: status == DepositStatus.rejected &&
              trimmedReason != null &&
              trimmedReason.isNotEmpty
          ? trimmedReason
          : existingDeposit.rejectionReason,
    );
    _depositController(tripId).add(_sortedDepositsForTrip(tripId));

    if (isTransitionToApproved) {
      final fund = _fundConfigs[tripId];
      if (fund != null) {
        final updatedFund = fund.copyWith(
          currentCollectedAmount: fund.currentCollectedAmount + existingDeposit.amount,
          updatedAt: DateTime.now(),
        );
        _fundConfigs[tripId] = updatedFund;
        _fundController(tripId).add(updatedFund);
      }

      if (existingDeposit.memberId.isNotEmpty) {
        final planKey = '${tripId}_${existingDeposit.memberId}';
        final plan = _savingPlans[planKey];
        if (plan != null) {
          final updatedPaid = plan.paidAmount + existingDeposit.amount;
          final updatedCompleted = plan.completedInstallments + 1;
          final updatedPlan = plan.copyWith(
            paidAmount: updatedPaid,
            completedInstallments: updatedCompleted,
            status: updatedPaid >= plan.targetAmount
                ? SavingPlanStatus.completed
                : plan.status,
          );
          _savingPlans[planKey] = updatedPlan;
          _planController(planKey).add(updatedPlan);
          _tripPlansController(tripId).add(List.unmodifiable(_plansForTrip(tripId)));
        }

        final streakKey = '${tripId}_${existingDeposit.memberId}';
        final currentStreak = _streaks[streakKey] ??
            MemberStreak(memberId: existingDeposit.memberId, tripId: tripId);
        final updatedStreak = SavingStreakCalculator.recordCheckIn(
          currentStreak,
          existingDeposit.depositDate,
          referenceDate: DateTime.now(),
        );
        _streaks[streakKey] = updatedStreak;
        _streakController(streakKey).add(updatedStreak);
        _tripStreaksController(tripId).add(List.unmodifiable(_streaksForTrip(tripId)));
      }
    }
  }

  @override
  Future<MemberStreak> getMemberStreak(String tripId, String memberId) async {
    return _streaks['${tripId}_$memberId'] ?? MemberStreak(memberId: memberId, tripId: tripId);
  }

  @override
  Stream<MemberStreak> watchMemberStreak(String tripId, String memberId) async* {
    final key = '${tripId}_$memberId';
    yield _streaks[key] ?? MemberStreak(memberId: memberId, tripId: tripId);
    yield* _streakController(key).stream;
  }

  @override
  Stream<List<MemberStreak>> watchTripStreaks(String tripId) async* {
    yield List.unmodifiable(_streaksForTrip(tripId));
    yield* _tripStreaksController(tripId).stream;
  }

  @override
  Future<void> updateMemberStreak(MemberStreak streak) async {
    final key = '${streak.tripId}_${streak.memberId}';
    _streaks[key] = streak;
    _streakController(key).add(streak);
    _tripStreaksController(streak.tripId).add(List.unmodifiable(_streaksForTrip(streak.tripId)));
  }
}
