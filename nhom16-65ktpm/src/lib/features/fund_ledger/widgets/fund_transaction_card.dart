import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/fund_transaction_model.dart';

/// Widget thẻ hiển thị một giao dịch trong Sổ Quỹ (FundTransactionCard)
/// Thể hiện trực quan loại giao dịch Thu (+)/Chi (-), số tiền, danh mục, ngày giờ và người thực hiện
class FundTransactionCard extends StatelessWidget {
  final FundTransactionModel transaction;
  final VoidCallback? onTap;

  const FundTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = transaction.isIncome;
    final statusColor = isIncome ? AppColors.success : AppColors.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon tròn phân biệt Thu / Chi
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // 2. Thông tin chi tiết giao dịch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Badge danh mục & thời gian ghi nhận
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          transaction.formattedCreatedAt,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Người đóng góp / Đơn vị thụ hưởng
                    Row(
                      children: [
                        Icon(
                          isIncome
                              ? Icons.volunteer_activism_outlined
                              : Icons.handshake_outlined,
                          size: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            transaction.recipientOrSponsor,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Huy hiệu có đính kèm chứng từ
                        if (transaction.proofImagePath != null &&
                            transaction.proofImagePath!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(width: 6),
                              Icon(Icons.attachment_rounded,
                                  size: 13, color: AppColors.primary),
                              SizedBox(width: 2),
                              Text(
                                'Chứng từ',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.primary),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 3. Số tiền biến động
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
