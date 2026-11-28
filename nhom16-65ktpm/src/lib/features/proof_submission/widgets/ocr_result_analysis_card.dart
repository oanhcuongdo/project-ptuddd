import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../mlkit_ocr_service.dart';
import '../models/ocr_analysis_detail.dart';

/// Widget hiển thị thẻ phân tích chuyên sâu AI OCR từ ảnh check-in & bài làm (Sprint 3 - Giai đoạn 4).
/// Bao gồm thanh điểm tin cậy (Confidence Score %), giờ đồng hồ, chỉ số bài làm,
/// gợi ý chuyển đúng loại thử thách và nút tự động điền ghi chú (Auto-fill).
class OcrResultAnalysisCard extends StatelessWidget {
  const OcrResultAnalysisCard({
    super.key,
    required this.result,
    required this.selectedChallengeId,
    this.capturedAt,
    this.suggestedChallengeTitle,
    this.onApplySuggestedChallenge,
    this.onAutoFillNote,
  });

  final OcrScanResult result;
  final String selectedChallengeId;
  final DateTime? capturedAt;
  final String? suggestedChallengeTitle;
  final VoidCallback? onApplySuggestedChallenge;
  final VoidCallback? onAutoFillNote;

  Color _resolveScoreColor(OcrConfidenceLevel level) {
    switch (level) {
      case OcrConfidenceLevel.high:
        return AppColors.success;
      case OcrConfidenceLevel.medium:
        return AppColors.warning;
      case OcrConfidenceLevel.low:
        return AppColors.danger;
      case OcrConfidenceLevel.unverified:
        return Colors.grey;
    }
  }

  String _metricDisplayLabel(String key) {
    switch (key) {
      case 'so_bai_hoan_thanh':
        return 'Bài làm';
      case 'si_so_lop':
        return 'Lớp học';
      case 'quang_duong':
        return 'Cự ly';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = result.analysisDetail;
    final score = detail?.confidenceScore ?? 0;
    final level = detail?.confidenceLevel ?? OcrConfidenceLevel.unverified;
    final scoreColor = _resolveScoreColor(level);
    final timeFormat = DateFormat('HH:mm:ss - dd/MM/yyyy');

    final hasMismatchSuggestion =
        detail != null &&
        detail.suggestedChallengeId != null &&
        detail.suggestedChallengeId != selectedChallengeId &&
        suggestedChallengeTitle != null;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Nhãn độ tin cậy AI
            Row(
              children: [
                Icon(
                  level == OcrConfidenceLevel.high
                      ? Icons.verified_rounded
                      : Icons.psychology_alt_outlined,
                  color: scoreColor,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '4. Phân tích AI OCR (Giờ & Bài làm)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    detail?.confidenceBadgeLabel ?? result.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),

            if (detail != null && detail.hasText) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
            ],

            const Divider(height: 24),

            if (capturedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Thời điểm ghi nhận hệ thống: ${timeFormat.format(capturedAt!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            // Thông tin giờ đồng hồ, ngày tháng & buổi trong ngày
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.schedule, size: 16),
                  label: Text(
                    'Giờ ảnh: ${result.extractedTime ?? 'Chưa rõ'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (result.extractedDate != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 15),
                    label: Text(
                      result.extractedDate!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (result.detectedPeriod != null)
                  Chip(
                    avatar: const Icon(Icons.wb_twilight, size: 16),
                    label: Text(
                      result.detectedPeriod!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),

            // Chỉ số định lượng đọc từ bài làm (số bài toán, sĩ số, cự ly km)
            if (detail != null && detail.homeworkMetrics.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: detail.homeworkMetrics.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_metricDisplayLabel(entry.key)}: ${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            const Text(
              'Văn bản nhận diện trên ảnh:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.rawText.isEmpty ? '(Không có văn bản)' : result.rawText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),

            if (result.detectedKeywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Từ khóa bài làm / hoạt động phát hiện:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.detectedKeywords
                    .map((kw) => Chip(label: Text(kw)))
                    .toList(),
              ),
            ],

            // Gợi ý chuyển đúng thử thách nếu ảnh chụp thuộc danh mục khác
            if (hasMismatchSuggestion) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI phát hiện nội dung ảnh giống với thử thách "$suggestedChallengeTitle".',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: onApplySuggestedChallenge,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Chuyển sang thử thách gợi ý'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scoreColor.withValues(alpha: 0.35)),
              ),
              child: Text(result.validationMessage),
            ),

            if (result.hasText && onAutoFillNote != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onAutoFillNote,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Tự động điền vào ghi chú'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
