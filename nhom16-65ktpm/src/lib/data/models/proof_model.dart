import 'dart:convert';
import 'package:intl/intl.dart';

enum ProofStatus {
  pending,
  approved,
  rejected,
}

/// Model cho bảng `proofs`
class ProofModel {
  final String id;
  final String challengeId;
  final String challengeTitle;
  final String memberName;
  final String imagePath;
  final String ocrExtractedText;
  final String? detectedTime;
  final DateTime submittedAt;
  final ProofStatus status;
  final double rewardAmount;
  final String note;
  final String? adminFeedback;

  const ProofModel({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.memberName,
    required this.imagePath,
    required this.ocrExtractedText,
    this.detectedTime,
    required this.submittedAt,
    this.status = ProofStatus.pending,
    required this.rewardAmount,
    this.note = '',
    this.adminFeedback,
  });

  bool get isPending => status == ProofStatus.pending;
  bool get isApproved => status == ProofStatus.approved;
  bool get isRejected => status == ProofStatus.rejected;

  String get statusDisplay {
    switch (status) {
      case ProofStatus.pending:
        return 'Chờ duyệt';
      case ProofStatus.approved:
        return 'Đã duyệt';
      case ProofStatus.rejected:
        return 'Từ chối';
    }
  }

  String get formattedRewardAmount {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(rewardAmount);
  }

  String get formattedSubmittedAt {
    final formatter = DateFormat('HH:mm - dd/MM/yyyy');
    return formatter.format(submittedAt);
  }

  /// Chuyển đối tượng thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'memberName': memberName,
      'imagePath': imagePath,
      'ocrExtractedText': ocrExtractedText,
      'detectedTime': detectedTime,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status.name,
      'rewardAmount': rewardAmount,
      'note': note,
      'adminFeedback': adminFeedback,
    };
  }

  /// Khởi tạo đối tượng từ Map lấy từ SQLite
  factory ProofModel.fromMap(Map<String, dynamic> map) {
    return ProofModel(
      id: map['id'] as String,
      challengeId: map['challengeId'] as String,
      challengeTitle: map['challengeTitle'] as String? ?? '',
      memberName: map['memberName'] as String,
      imagePath: map['imagePath'] as String,
      ocrExtractedText: map['ocrExtractedText'] as String? ?? '',
      detectedTime: map['detectedTime'] as String?,
      submittedAt: DateTime.parse(map['submittedAt'] as String),
      status: ProofStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProofStatus.pending,
      ),
      rewardAmount: (map['rewardAmount'] as num).toDouble(),
      note: map['note'] as String? ?? '',
      adminFeedback: map['adminFeedback'] as String?,
    );
  }

  /// JSON Serialization
  Map<String, dynamic> toJson() => toMap();

  factory ProofModel.fromJson(Map<String, dynamic> json) =>
      ProofModel.fromMap(json);

  String toJsonString() => jsonEncode(toJson());

  factory ProofModel.fromJsonString(String source) =>
      ProofModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  ProofModel copyWith({
    String? id,
    String? challengeId,
    String? challengeTitle,
    String? memberName,
    String? imagePath,
    String? ocrExtractedText,
    String? detectedTime,
    DateTime? submittedAt,
    ProofStatus? status,
    double? rewardAmount,
    String? note,
    String? adminFeedback,
  }) {
    return ProofModel(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      memberName: memberName ?? this.memberName,
      imagePath: imagePath ?? this.imagePath,
      ocrExtractedText: ocrExtractedText ?? this.ocrExtractedText,
      detectedTime: detectedTime ?? this.detectedTime,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      note: note ?? this.note,
      adminFeedback: adminFeedback ?? this.adminFeedback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProofModel &&
        other.id == id &&
        other.challengeId == challengeId &&
        other.challengeTitle == challengeTitle &&
        other.memberName == memberName &&
        other.imagePath == imagePath &&
        other.ocrExtractedText == ocrExtractedText &&
        other.detectedTime == detectedTime &&
        other.submittedAt == submittedAt &&
        other.status == status &&
        other.rewardAmount == rewardAmount &&
        other.note == note &&
        other.adminFeedback == adminFeedback;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      challengeId,
      challengeTitle,
      memberName,
      imagePath,
      ocrExtractedText,
      detectedTime,
      submittedAt,
      status,
      rewardAmount,
      note,
      adminFeedback,
    );
  }
}
