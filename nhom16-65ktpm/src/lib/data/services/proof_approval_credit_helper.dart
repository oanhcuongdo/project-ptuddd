import '../models/challenge_model.dart';
import '../models/fund_transaction_model.dart';
import '../models/proof_model.dart';

/// Trạng thái chi tiết khi Admin duyệt minh chứng và tự động cộng tiền Thu vào quỹ.
enum ApprovalCreditStatus {
  /// Duyệt minh chứng và cộng tiền Thu vào quỹ thành công.
  credited,

  /// Không tìm thấy minh chứng theo mã proofId.
  notFound,

  /// Minh chứng không còn ở trạng thái chờ duyệt (đã Approved hoặc Rejected).
  alreadyProcessed,

  /// Đã tồn tại giao dịch Thu gắn với proofId này (chống cộng trùng tiền).
  duplicateTransaction,

  /// Số tiền thưởng của minh chứng không hợp lệ (<= 0).
  invalidRewardAmount,
}

/// Kết quả trả về của nghiệp vụ duyệt minh chứng kèm tự động cộng quỹ.
class ApprovalCreditResult {
  const ApprovalCreditResult({
    required this.approved,
    required this.status,
    required this.message,
    this.transaction,
    this.newBalance,
  });

  final bool approved;
  final ApprovalCreditStatus status;
  final String message;

  /// Giao dịch Thu vừa được tự động sinh vào Sổ Quỹ (nếu approved == true).
  final FundTransactionModel? transaction;

  /// Số dư quỹ mới nhất sau khi đã cộng tiền thưởng (nếu approved == true).
  final double? newBalance;
}

/// Lớp nghiệp vụ chuẩn hoá việc tạo giao dịch THU tự động vào Sổ Quỹ
/// khi một minh chứng việc tốt được Admin phê duyệt (Approved).
class ProofApprovalCreditHelper {
  const ProofApprovalCreditHelper._();

  static const String defaultSponsorName = 'Quỹ Bảo trợ Thử thách Việc tốt';
  static const String defaultAdminFeedback =
      'Minh chứng hợp lệ. Đã duyệt cộng quỹ!';

  /// Kiểm tra điều kiện hợp lệ để một minh chứng có thể được duyệt và cộng quỹ.
  static bool canCreditFund(ProofModel proof) {
    return proof.isPending && proof.rewardAmount > 0;
  }

  /// Chuẩn hoá phản hồi của Admin khi duyệt minh chứng.
  static String normalizeFeedback(String? adminFeedback) {
    final trimmed = adminFeedback?.trim() ?? '';
    return trimmed.isEmpty ? defaultAdminFeedback : trimmed;
  }

  /// Khởi tạo đối tượng giao dịch THU (`TransactionType.thu`) tương ứng
  /// từ minh chứng đã duyệt và thông tin thử thách gốc.
  static FundTransactionModel buildIncomeTransaction({
    required ProofModel proof,
    ChallengeModel? challenge,
    String? adminFeedback,
    DateTime? approvedAt,
  }) {
    if (proof.rewardAmount <= 0) {
      throw ArgumentError.value(
        proof.rewardAmount,
        'proof.rewardAmount',
        'Số tiền thưởng cộng quỹ phải lớn hơn 0',
      );
    }

    final now = approvedAt ?? DateTime.now();
    final resolvedCategory =
        (challenge != null && challenge.category.trim().isNotEmpty)
            ? challenge.category.trim()
            : proof.challengeTitle.trim();

    final trimmedFeedback = adminFeedback?.trim() ?? '';
    final noteBuffer = StringBuffer(
      'Minh chứng của ${proof.memberName} được Admin duyệt thành công.',
    );
    if (trimmedFeedback.isNotEmpty) {
      noteBuffer.write(' Phản hồi: $trimmedFeedback');
    }

    final trimmedImagePath = proof.imagePath.trim();

    return FundTransactionModel(
      id: 'tx_proof_${proof.id}_${now.millisecondsSinceEpoch}',
      proofId: proof.id,
      type: TransactionType.thu,
      amount: proof.rewardAmount,
      title: 'Tài trợ: ${proof.challengeTitle}',
      category: resolvedCategory,
      proofImagePath: trimmedImagePath.isNotEmpty ? trimmedImagePath : null,
      note: noteBuffer.toString(),
      recipientOrSponsor: defaultSponsorName,
      createdAt: now,
    );
  }
}
