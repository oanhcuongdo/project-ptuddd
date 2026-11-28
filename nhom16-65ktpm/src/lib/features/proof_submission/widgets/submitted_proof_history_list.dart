import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/proof_model.dart';

/// Widget hiển thị danh sách minh chứng vừa nộp và lưu trong bộ nhớ máy (Sprint 2 - Sprint 3).
class SubmittedProofHistoryList extends StatelessWidget {
  const SubmittedProofHistoryList({
    super.key,
    required this.proofs,
  });

  final List<ProofModel> proofs;

  String _formatCurrency(double amount) =>
      '${NumberFormat.decimalPattern('vi_VN').format(amount.round())} đ';

  String _summarizeOcrText(String rawText) {
    final cleaned = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' • ');
    return cleaned;
  }

  (String, Color) _statusBadge(ProofStatus status) {
    switch (status) {
      case ProofStatus.approved:
        return ('Đã duyệt', AppColors.success);
      case ProofStatus.rejected:
        return ('Từ chối', AppColors.danger);
      case ProofStatus.pending:
        return ('Chờ duyệt', AppColors.warning);
    }
  }

  void _showStoredImageDialog(BuildContext context, ProofModel proof) {
    if (kIsWeb ||
        proof.imagePath.isEmpty ||
        proof.imagePath.startsWith('mock://')) {
      return;
    }
    final file = File(proof.imagePath);
    if (!file.existsSync()) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      proof.challengeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (proof.ocrExtractedText.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Văn bản AI OCR: ${_summarizeOcrText(proof.ocrExtractedText)}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Đường dẫn tệp: ${proof.imagePath}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingThumbnail(BuildContext context, ProofModel proof) {
    if (!kIsWeb &&
        proof.imagePath.isEmpty == false &&
        !proof.imagePath.startsWith('mock://')) {
      final file = File(proof.imagePath);
      if (file.existsSync()) {
        return InkWell(
          onTap: () => _showStoredImageDialog(context, proof),
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minh chứng đã lưu trên máy (${proofs.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (proofs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có minh chứng nào được lưu. Hãy chụp ảnh và nhấn Gửi minh chứng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: proofs.length,
                separatorBuilder: (_, _) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final item = proofs[index];
                  final (statusText, statusColor) = _statusBadge(item.status);
                  final ocrPreview = _summarizeOcrText(item.ocrExtractedText);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeadingThumbnail(context, item),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.challengeTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Người nộp: ${item.memberName} • Tài trợ: ${_formatCurrency(item.rewardAmount)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Nộp lúc: ${dateFormat.format(item.submittedAt)}'
                              '${item.detectedTime != null ? ' • Giờ OCR: ${item.detectedTime}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (ocrPreview.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  'OCR: $ocrPreview',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            if (item.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Ghi chú: ${item.note}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Tệp ảnh: ${item.imagePath}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
