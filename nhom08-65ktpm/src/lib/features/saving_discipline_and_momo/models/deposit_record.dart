import 'package:cloud_firestore/cloud_firestore.dart';

import 'saving_plan.dart';

enum DepositStatus { pending, approved, rejected }

class DepositRecord {
  final String id;
  final String tripId;
  final String memberId;
  final String memberName;
  final double amount;
  final int installmentIndex;
  final DateTime depositDate;
  final String? receiptImageUrl;
  final DepositStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? note;
  final String? emotionTag; // 'happy', 'excited', 'disciplined', 'coffee_cut'
  final String? rejectionReason;
  final DateTime? termDueDate;
  final SavingFrequency? termFrequency;

  const DepositRecord({
    required this.id,
    required this.tripId,
    required this.memberId,
    required this.memberName,
    required this.amount,
    this.installmentIndex = 0,
    required this.depositDate,
    this.receiptImageUrl,
    this.status = DepositStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.note,
    this.emotionTag,
    this.rejectionReason,
    this.termDueDate,
    this.termFrequency,
  });

  factory DepositRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawStatus = (map['status'] as String? ?? 'pending').toLowerCase();
    DepositStatus status;
    switch (rawStatus) {
      case 'approved':
        status = DepositStatus.approved;
        break;
      case 'rejected':
        status = DepositStatus.rejected;
        break;
      default:
        status = DepositStatus.pending;
    }

    final rawFreq = map['termFrequency'] as String?;
    SavingFrequency? termFrequency;
    if (rawFreq != null) {
      switch (rawFreq.toLowerCase()) {
        case 'daily':
          termFrequency = SavingFrequency.daily;
        case 'weekly':
          termFrequency = SavingFrequency.weekly;
        case 'monthly':
          termFrequency = SavingFrequency.monthly;
      }
    }

    return DepositRecord(
      id: id ?? (map['id'] as String? ?? ''),
      tripId: map['tripId'] as String? ?? '',
      memberId: map['memberId'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      installmentIndex: (map['installmentIndex'] as num?)?.toInt() ?? 0,
      depositDate: parseDate(map['depositDate']),
      receiptImageUrl: map['receiptImageUrl'] as String?,
      status: status,
      approvedBy: map['approvedBy'] as String?,
      approvedAt: parseNullableDate(map['approvedAt']),
      note: map['note'] as String?,
      emotionTag: map['emotionTag'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      termDueDate: parseNullableDate(map['termDueDate']),
      termFrequency: termFrequency,
    );
  }

  Map<String, dynamic> toMap() {
    String statusString;
    switch (status) {
      case DepositStatus.approved:
        statusString = 'APPROVED';
        break;
      case DepositStatus.rejected:
        statusString = 'REJECTED';
        break;
      case DepositStatus.pending:
        statusString = 'PENDING';
        break;
    }

    return {
      'id': id,
      'tripId': tripId,
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'installmentIndex': installmentIndex,
      'depositDate': Timestamp.fromDate(depositDate),
      if (receiptImageUrl != null) 'receiptImageUrl': receiptImageUrl,
      'status': statusString,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (note != null) 'note': note,
      if (emotionTag != null) 'emotionTag': emotionTag,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (termDueDate != null) 'termDueDate': Timestamp.fromDate(termDueDate!),
      if (termFrequency != null) 'termFrequency': termFrequency!.name,
    };
  }

  DepositRecord copyWith({
    String? id,
    String? tripId,
    String? memberId,
    String? memberName,
    double? amount,
    int? installmentIndex,
    DateTime? depositDate,
    String? receiptImageUrl,
    DepositStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? note,
    String? emotionTag,
    String? rejectionReason,
    DateTime? termDueDate,
    SavingFrequency? termFrequency,
  }) {
    return DepositRecord(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      amount: amount ?? this.amount,
      installmentIndex: installmentIndex ?? this.installmentIndex,
      depositDate: depositDate ?? this.depositDate,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      note: note ?? this.note,
      emotionTag: emotionTag ?? this.emotionTag,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      termDueDate: termDueDate ?? this.termDueDate,
      termFrequency: termFrequency ?? this.termFrequency,
    );
  }
}
