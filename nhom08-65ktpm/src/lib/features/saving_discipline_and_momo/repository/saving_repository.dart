import 'dart:io';
import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../models/deposit_record.dart';
import '../models/member_streak.dart';

abstract class SavingRepository {
  /// MoMo Fund Config
  Future<MoMoFundConfig?> getFundConfig(String tripId);
  Stream<MoMoFundConfig?> watchFundConfig(String tripId);
  Future<void> saveFundConfig(MoMoFundConfig config);

  /// Saving Plan
  Future<SavingPlan?> getSavingPlan(String tripId, String memberId);
  Stream<SavingPlan?> watchSavingPlan(String tripId, String memberId);
  Stream<List<SavingPlan>> watchTripSavingPlans(String tripId);
  Future<void> saveSavingPlan(SavingPlan plan);

  /// Deposit Records
  Future<void> submitDeposit(DepositRecord record, {File? receiptImage});
  Future<List<DepositRecord>> getPendingDeposits(String tripId);
  Stream<List<DepositRecord>> watchPendingDeposits(String tripId);
  Stream<List<DepositRecord>> watchTripDeposits(String tripId);
  Stream<List<DepositRecord>> watchMemberDeposits(String tripId, String memberId);
  Future<void> updateDepositStatus({
    required String tripId,
    required String depositId,
    required DepositStatus status,
    required String reviewerId,
    String? rejectionReason,
  });

  /// Streaks
  Future<MemberStreak> getMemberStreak(String tripId, String memberId);
  Stream<MemberStreak> watchMemberStreak(String tripId, String memberId);
  Stream<List<MemberStreak>> watchTripStreaks(String tripId);
  Future<void> updateMemberStreak(MemberStreak streak);
}
