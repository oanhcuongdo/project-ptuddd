import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../styles/topics_styles.dart';

/// Giao diện trạng thái đang tải danh sách chủ đề.
class TopicsLoadingView extends StatelessWidget {
  const TopicsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: TopicsStyles.tealPrimary),
            SizedBox(height: 14),
            Text(
              'Đang tải kho chủ đề hội thoại A1–B2...',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Giao diện trạng thái trống khi không có chủ đề khớp bộ lọc hiện tại.
class TopicsEmptyView extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onResetFilters;

  const TopicsEmptyView({
    super.key,
    required this.hasActiveFilters,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: TopicsStyles.filterSurfaceDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: TopicsStyles.tealSoftBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: TopicsStyles.tealPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasActiveFilters
                ? 'Không tìm thấy chủ đề phù hợp'
                : 'Chưa có chủ đề hội thoại nào',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasActiveFilters
                ? 'Hãy thử đổi cấp độ A1–B2, từ khóa tìm kiếm hoặc đặt lại bộ lọc.'
                : 'Kéo xuống để tải lại danh sách chủ đề từ hệ thống.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onResetFilters,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Đặt lại bộ lọc'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TopicsStyles.tealDark,
                side: const BorderSide(color: TopicsStyles.tealPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner cảnh báo lỗi nhỏ gọn (có nút đóng & nút thử lại) khi tải hoặc lưu tiến độ thất bại.
class TopicsErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const TopicsErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Thử lại'),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Đóng thông báo',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: const Color(0xFF991B1B),
          ),
        ],
      ),
    );
  }
}

