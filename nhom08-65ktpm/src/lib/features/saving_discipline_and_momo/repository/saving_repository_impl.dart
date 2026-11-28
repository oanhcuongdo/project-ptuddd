import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_storage_service.dart';
import '../../../models/trip_member.dart';
import '../../../models/trip_model.dart';
import '../models/deposit_record.dart';
import '../models/member_streak.dart';
import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../utils/saving_streak_calculator.dart';
import 'in_memory_saving_repository.dart';
import 'saving_repository.dart';

final savingRepositoryProvider = Provider<SavingRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return InMemorySavingRepository(seedDemo: true);
  }
  return SavingRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    storageService: ref.watch(supabaseStorageServiceProvider),
  );
});

class SavingRepositoryImpl implements SavingRepository {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storageService;

  SavingRepositoryImpl({
    FirebaseFirestore? firestore,
    SupabaseStorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? SupabaseStorageService();

  // --- Collection references ---
  DocumentReference _tripDoc(String tripId) =>
      _firestore.collection('trips').doc(tripId);

  DocumentReference _memberDoc(String tripId, String memberId) =>
      _tripDoc(tripId).collection('members').doc(memberId);

  DocumentReference _fundConfigDoc(String tripId) =>
      _tripDoc(tripId).collection('momo_fund_config').doc('default');

  CollectionReference _savingPlansColl(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('saving_plans');

  DocumentReference _savingPlanDoc(String tripId, String memberId) =>
      _savingPlansColl(tripId).doc(memberId);

  CollectionReference _depositRecordsColl(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('deposit_records');

  CollectionReference _memberStreaksColl(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('member_streaks');

  DocumentReference _memberStreakDoc(String tripId, String memberId) =>
      _memberStreaksColl(tripId).doc(memberId);

  // --- Trip & Members (Read-only sync) ---
  @override
  Stream<TripModel?> watchTripSummary(String tripId) {
    return _tripDoc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TripModel.fromJson({
        ...(doc.data() as Map<String, dynamic>),
        'id': doc.id,
      });
    });
  }

  @override
  Stream<List<TripMember>> watchTripMembers(String tripId) {
    return _tripDoc(tripId).collection('members').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => TripMember.fromJson({...d.data(), 'userId': d.id}))
          .toList();
      list.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
      return list;
    });
  }

  // --- MoMo Fund Config ---
  @override
  Future<MoMoFundConfig?> getFundConfig(String tripId) async {
    final doc = await _fundConfigDoc(tripId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MoMoFundConfig.fromMap(doc.data() as Map<String, dynamic>, tripId: tripId);
  }

  @override
  Stream<MoMoFundConfig?> watchFundConfig(String tripId) {
    return _fundConfigDoc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MoMoFundConfig.fromMap(doc.data() as Map<String, dynamic>, tripId: tripId);
    });
  }

  @override
  Future<void> saveFundConfig(MoMoFundConfig config) async {
    final membersSnap = await _tripDoc(config.tripId).collection('members').get();
    final plansSnap = await _savingPlansColl(config.tripId).get();

    final memberCount = membersSnap.docs.length;
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

    // shortcut: single WriteBatch assumes <= 240 trip members (< 500 Firestore ops), chunk if trips grow larger.
    final batch = _firestore.batch();
    batch.set(
      _fundConfigDoc(effectiveConfig.tripId),
      effectiveConfig.toMap(),
      SetOptions(merge: true),
    );

    final perMemberTotal = (memberCount > 0 && effectiveConfig.targetTotalAmount > 0)
        ? (effectiveConfig.targetTotalAmount / memberCount).round()
        : 0;

    if (perMemberTotal > 0) {
      for (final memberDoc in membersSnap.docs) {
        batch.update(memberDoc.reference, {
          'targetContribution': perMemberTotal,
        });
      }
    }

    for (final planDoc in plansSnap.docs) {
      final plan = SavingPlan.fromMap(
        planDoc.data() as Map<String, dynamic>,
        id: planDoc.id,
      );
      final updatedPlan = MoMoFundConfig.applyGroupConfigToPlan(
        plan: plan,
        perMemberTotalTarget:
            perMemberTotal > 0 ? perMemberTotal.toDouble() : plan.targetAmount,
        defaultFrequency: effectiveConfig.defaultFrequency,
      );
      batch.update(planDoc.reference, {
        'targetAmount': updatedPlan.targetAmount,
        'frequency': updatedPlan.frequency.name,
        'installmentAmount': updatedPlan.installmentAmount,
        'totalInstallments': updatedPlan.totalInstallments,
        'status': updatedPlan.status.name,
      });
    }

    await batch.commit();
  }

  // --- Saving Plan ---
  @override
  Future<SavingPlan?> getSavingPlan(String tripId, String memberId) async {
    final doc = await _savingPlanDoc(tripId, memberId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SavingPlan.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  @override
  Stream<SavingPlan?> watchSavingPlan(String tripId, String memberId) {
    return _savingPlanDoc(tripId, memberId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SavingPlan.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    });
  }

  @override
  Stream<List<SavingPlan>> watchTripSavingPlans(String tripId) {
    return _savingPlansColl(tripId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((d) => SavingPlan.fromMap(d.data() as Map<String, dynamic>, id: d.id))
              .toList(),
        );
  }

  @override
  Future<void> saveSavingPlan(SavingPlan plan) async {
    await _savingPlanDoc(plan.tripId, plan.memberId).set(plan.toMap(), SetOptions(merge: true));
  }

  // --- Deposit Records ---
  @override
  Future<void> submitDeposit(DepositRecord record, {File? receiptImage}) async {
    String? imageUrl = record.receiptImageUrl;
    String? uploadedPath;

    if (receiptImage != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${record.id}.jpg';
      uploadedPath = 'trips/${record.tripId}/receipts/$fileName';
      imageUrl = await _storageService.uploadFile(
        path: uploadedPath,
        file: receiptImage,
      );
    }

    final recordToSave = record.copyWith(receiptImageUrl: imageUrl);
    try {
      await _depositRecordsColl(record.tripId).doc(record.id).set(recordToSave.toMap());
    } catch (_) {
      if (uploadedPath != null) {
        try {
          await _storageService.deleteFile(uploadedPath);
        } catch (_) {
          // Best-effort cleanup so the original Firestore error is preserved.
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<DepositRecord>> getPendingDeposits(String tripId) async {
    final snapshot = await _depositRecordsColl(tripId)
        .where('status', isEqualTo: 'PENDING')
        .get();

    final list = snapshot.docs
        .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
        .toList();
    list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
    return list;
  }

  @override
  Stream<List<DepositRecord>> watchPendingDeposits(String tripId) {
    return _depositRecordsColl(tripId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
          .toList();
      list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
      return list;
    });
  }

  @override
  Stream<List<DepositRecord>> watchTripDeposits(String tripId) {
    return _depositRecordsColl(tripId).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
          .toList();
      list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
      return list;
    });
  }

  @override
  Stream<List<DepositRecord>> watchMemberDeposits(String tripId, String memberId) {
    return _depositRecordsColl(tripId)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => DepositRecord.fromMap(d.data() as Map<String, dynamic>, id: d.id))
          .toList();
      list.sort((a, b) => b.depositDate.compareTo(a.depositDate));
      return list;
    });
  }

  @override
  Future<void> updateDepositStatus({
    required String tripId,
    required String depositId,
    required DepositStatus status,
    required String reviewerId,
    String? rejectionReason,
  }) async {
    final depositRef = _depositRecordsColl(tripId).doc(depositId);

    // Firestore transactions require all reads before any writes.
    await _firestore.runTransaction((transaction) async {
      final depositSnap = await transaction.get(depositRef);
      if (!depositSnap.exists) {
        throw Exception('Deposit record $depositId not found.');
      }
      final depositData = depositSnap.data() as Map<String, dynamic>;
      final parsedDeposit = DepositRecord.fromMap(depositData, id: depositSnap.id);
      final isTransitionToApproved =
          status == DepositStatus.approved && parsedDeposit.status != DepositStatus.approved;

      final tripRef = _tripDoc(tripId);
      final memberDocRef = parsedDeposit.memberId.isNotEmpty
          ? _memberDoc(tripId, parsedDeposit.memberId)
          : null;
      final fundDocRef = _fundConfigDoc(tripId);
      final planDocRef = parsedDeposit.memberId.isNotEmpty
          ? _savingPlanDoc(tripId, parsedDeposit.memberId)
          : null;
      final streakDocRef = parsedDeposit.memberId.isNotEmpty
          ? _memberStreakDoc(tripId, parsedDeposit.memberId)
          : null;

      DocumentSnapshot? tripSnap;
      DocumentSnapshot? memberSnap;
      DocumentSnapshot? fundSnap;
      DocumentSnapshot? planSnap;
      DocumentSnapshot? streakSnap;

      if (isTransitionToApproved) {
        tripSnap = await transaction.get(tripRef);
        if (memberDocRef != null) {
          memberSnap = await transaction.get(memberDocRef);
        }
        fundSnap = await transaction.get(fundDocRef);
        if (planDocRef != null) {
          planSnap = await transaction.get(planDocRef);
        }
        if (streakDocRef != null) {
          streakSnap = await transaction.get(streakDocRef);
        }
      }

      final statusStr = switch (status) {
        DepositStatus.approved => 'APPROVED',
        DepositStatus.rejected => 'REJECTED',
        DepositStatus.pending => 'PENDING',
      };

      final trimmedReason = rejectionReason?.trim();
      final updatePayload = <String, dynamic>{
        'status': statusStr,
        'approvedBy': reviewerId,
        'approvedAt': Timestamp.now(),
        if (status == DepositStatus.rejected && trimmedReason != null && trimmedReason.isNotEmpty)
          'rejectionReason': trimmedReason,
      };
      transaction.update(depositRef, updatePayload);

      if (isTransitionToApproved) {
        final amountInt = parsedDeposit.amount.round();
        final nowTs = Timestamp.now();

        if (tripSnap != null && tripSnap.exists) {
          transaction.update(tripRef, {
            'totalSavedAmount': FieldValue.increment(amountInt),
            'updatedAt': nowTs,
          });
        }

        if (fundSnap != null && fundSnap.exists) {
          transaction.update(fundDocRef, {
            'currentCollectedAmount': FieldValue.increment(parsedDeposit.amount),
            'updatedAt': nowTs,
          });
        }

        if (planDocRef != null && planSnap != null && planSnap.exists) {
          final planData = planSnap.data() as Map<String, dynamic>?;
          final currentPaid = (planData?['paidAmount'] as num?)?.toDouble() ?? 0.0;
          final targetAmount = (planData?['targetAmount'] as num?)?.toDouble() ?? 0.0;
          final isPlanCompleted =
              targetAmount > 0 && (currentPaid + parsedDeposit.amount) >= targetAmount;

          transaction.update(planDocRef, {
            'paidAmount': FieldValue.increment(parsedDeposit.amount),
            'completedInstallments': FieldValue.increment(1),
            if (isPlanCompleted) 'status': 'completed',
          });
        }

        MemberStreak? updatedStreak;
        if (streakDocRef != null) {
          final currentStreak = (streakSnap != null && streakSnap.exists && streakSnap.data() != null)
              ? MemberStreak.fromMap(
                  streakSnap.data() as Map<String, dynamic>,
                  memberId: parsedDeposit.memberId,
                  tripId: tripId,
                )
              : MemberStreak(memberId: parsedDeposit.memberId, tripId: tripId);

          updatedStreak = SavingStreakCalculator.recordCheckIn(
            currentStreak,
            parsedDeposit.depositDate,
            referenceDate: DateTime.now(),
          );
          transaction.set(streakDocRef, updatedStreak.toMap(), SetOptions(merge: true));
        }

        if (memberDocRef != null && memberSnap != null && memberSnap.exists) {
          transaction.update(memberDocRef, {
            'contributedAmount': FieldValue.increment(amountInt),
            if (updatedStreak != null) 'currentStreak': updatedStreak.currentStreak,
          });
        }
      }
    });
  }

  // --- Member Streak ---
  @override
  Future<MemberStreak> getMemberStreak(String tripId, String memberId) async {
    final doc = await _memberStreakDoc(tripId, memberId).get();
    if (!doc.exists || doc.data() == null) {
      return MemberStreak(memberId: memberId, tripId: tripId);
    }
    return MemberStreak.fromMap(doc.data() as Map<String, dynamic>, memberId: memberId, tripId: tripId);
  }

  @override
  Stream<MemberStreak> watchMemberStreak(String tripId, String memberId) {
    return _memberStreakDoc(tripId, memberId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return MemberStreak(memberId: memberId, tripId: tripId);
      }
      return MemberStreak.fromMap(doc.data() as Map<String, dynamic>, memberId: memberId, tripId: tripId);
    });
  }

  @override
  Stream<List<MemberStreak>> watchTripStreaks(String tripId) {
    return _memberStreaksColl(tripId).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (d) => MemberStreak.fromMap(
                  d.data() as Map<String, dynamic>,
                  memberId: d.id,
                  tripId: tripId,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> updateMemberStreak(MemberStreak streak) async {
    await _memberStreakDoc(streak.tripId, streak.memberId).set(streak.toMap(), SetOptions(merge: true));
  }
}
