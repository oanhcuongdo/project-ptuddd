import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';

/// Hộp thoại đối soát thông tin lần cuối trước khi ghi nhận phiếu chi giải ngân.
class DisbursementConfirmDialog extends StatelessWidget {
  final String title;
  final double amount;
  final double currentBalance;
  final String category;
  final String recipient;
  final String? transferReference;
  final String? receiptFileName;

  const DisbursementConfirmDialog({
    super.key,
    required this.title,
    required this.amount,
    required this.currentBalance,
    required this.category,
    required this.recipient,
    this.transferReference,
    this.receiptFileName,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required double amount,
    required double currentBalance,
    required String category,
    required String recipient,
    String? transferReference,
    String? receiptFileName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DisbursementConfirmDialog(
        title: title,
        amount: amount,
        currentBalance: currentBalance,
        category: category,
        recipient: recipient,
        transferReference: transferReference,
        receiptFileName: receiptFileName,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final remainingBalance = (currentBalance - amount).clamp(0.0, double.infinity);
    final hasReceipt =
        receiptFileName != null && receiptFileName!.trim().isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Xác nhận giải ngân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vui lòng kiểm tra kỹ thông tin phiếu chi trước khi ghi nhận vào Sổ Quỹ:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                    label: 'Mục đích chi',
                    value: title,
                    isBoldValue: true,
                  ),
                  _buildSummaryRow(
                    label: 'Số tiền chi',
                    value: '-${currencyFormatter.format(amount)}',
                    valueColor: AppColors.danger,
                    isBoldValue: true,
                  ),
                  _buildSummaryRow(
                    label: 'Số dư sau chi',
                    value: currencyFormatter.format(remainingBalance),
                    valueColor: AppColors.primaryDark,
                    isBoldValue: true,
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    label: 'Thụ hưởng',
                    value: recipient,
                  ),
                  _buildSummaryRow(
                    label: 'Danh mục',
                    value: category,
                  ),
                  if (transferReference != null &&
                      transferReference!.trim().isNotEmpty)
                    _buildSummaryRow(
                      label: 'Mã tham chiếu CK',
                      value: transferReference!.trim(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Trạng thái đính kèm sao kê
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (hasReceipt ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    hasReceipt
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: hasReceipt ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasReceipt
                          ? 'Đã đính kèm sao kê: $receiptFileName'
                          : 'Chưa đính kèm ảnh sao kê / uỷ nhiệm chi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            hasReceipt ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Huỷ bỏ'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text(
            'Đồng ý giải ngân',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
