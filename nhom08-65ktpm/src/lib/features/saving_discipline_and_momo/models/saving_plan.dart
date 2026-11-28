import 'package:cloud_firestore/cloud_firestore.dart';

enum SavingFrequency { daily, weekly, monthly }

enum SavingPlanStatus { active, completed }

class SavingPlan {
  final String id;
  final String tripId;
  final String memberId;
  final String memberName;
  final double targetAmount;
  final double paidAmount;
  final SavingFrequency frequency;
  final double installmentAmount;
  final int totalInstallments;
  final int completedInstallments;
  final DateTime startDate;
  final DateTime deadlineDate;
  final SavingPlanStatus status;

  const SavingPlan({
    required this.id,
    required this.tripId,
    required this.memberId,
    required this.memberName,
    required this.targetAmount,
    this.paidAmount = 0.0,
    required this.frequency,
    required this.installmentAmount,
    required this.totalInstallments,
    this.completedInstallments = 0,
    required this.startDate,
    required this.deadlineDate,
    this.status = SavingPlanStatus.active,
  });

  factory SavingPlan.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final freqStr = (map['frequency'] as String? ?? 'daily').toLowerCase();
    final freq = SavingFrequency.values.firstWhere(
      (e) => e.name == freqStr,
      orElse: () => SavingFrequency.daily,
    );

    final statusStr = (map['status'] as String? ?? 'active').toLowerCase();
    final status = SavingPlanStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => SavingPlanStatus.active,
    );

    return SavingPlan(
      id: id ?? (map['id'] as String? ?? ''),
      tripId: map['tripId'] as String? ?? '',
      memberId: map['memberId'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      frequency: freq,
      installmentAmount: (map['installmentAmount'] as num?)?.toDouble() ?? 0.0,
      totalInstallments: (map['totalInstallments'] as num?)?.toInt() ?? 0,
      completedInstallments: (map['completedInstallments'] as num?)?.toInt() ?? 0,
      startDate: parseDate(map['startDate']),
      deadlineDate: parseDate(map['deadlineDate']),
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'memberId': memberId,
      'memberName': memberName,
      'targetAmount': targetAmount,
      'paidAmount': paidAmount,
      'frequency': frequency.name,
      'installmentAmount': installmentAmount,
      'totalInstallments': totalInstallments,
      'completedInstallments': completedInstallments,
      'startDate': Timestamp.fromDate(startDate),
      'deadlineDate': Timestamp.fromDate(deadlineDate),
      'status': status.name,
    };
  }

  SavingPlan copyWith({
    String? id,
    String? tripId,
    String? memberId,
    String? memberName,
    double? targetAmount,
    double? paidAmount,
    SavingFrequency? frequency,
    double? installmentAmount,
    int? totalInstallments,
    int? completedInstallments,
    DateTime? startDate,
    DateTime? deadlineDate,
    SavingPlanStatus? status,
  }) {
    return SavingPlan(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      targetAmount: targetAmount ?? this.targetAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      frequency: frequency ?? this.frequency,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      completedInstallments: completedInstallments ?? this.completedInstallments,
      startDate: startDate ?? this.startDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      status: status ?? this.status,
    );
  }
}
