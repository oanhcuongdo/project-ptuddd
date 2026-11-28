import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/challenge_model.dart';

/// Màn hình Chi tiết Thử thách việc tốt (ChallengeDetailScreen)
/// Phụ trách: Nguyễn Văn Huỳnh (Nhóm trưởng)
/// Thiết kế chuẩn Material 3: Tone Teal & Cam ấm, bo góc mềm mại 20px,
/// hướng dẫn thể lệ AI OCR chi tiết và nút CTA chuyển sang màn hình nộp minh chứng.
class ChallengeDetailScreen extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onJoinNow;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
    this.onJoinNow,
  });

  /// Chuyển đổi tên icon thành IconData
  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'wb_sunny':
      case 'alarm':
        return Icons.alarm_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  /// Màu sắc theo danh mục
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Kỷ luật':
        return const Color(0xFFD97706);
      case 'Gia sư':
      case 'Cộng đồng':
        return AppColors.primary;
      case 'Học tập':
        return const Color(0xFF7C3AED);
      case 'Sức khỏe':
        return const Color(0xFF2563EB);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = getCategoryColor(challenge.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Thử Thách'),
        actions: [
          IconButton(
            tooltip: 'Chia sẻ thử thách',
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép liên kết thử thách: "${challenge.title}"'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BANNER HEADER THỬ THÁCH
            _buildHeroBanner(theme, isDark, catColor),
            const SizedBox(height: 18),

            // 2. LƯỚI 3 CHỈ SỐ NHANH
            _buildQuickStatTriplets(theme, catColor),
            const SizedBox(height: 20),

            // 3. THỂ LỆ & QUY TRÌNH THAM GIA
            _buildRulesCard(theme, isDark),
            const SizedBox(height: 18),

            // 4. TIÊU CHUẨN ẢNH CHỤP CHO AI OCR (GOOGLE ML KIT)
            _buildAiOcrStandardCard(theme, isDark),
            const SizedBox(height: 18),

            // 5. THÀNH VIÊN VỪA HOÀN THÀNH GẦN ĐÂY
            _buildRecentCompletionsCard(theme),
          ],
        ),
      ),

      // 6. BOTTOM ACTION BAR (STICKY CTA)
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onJoinNow?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.photo_camera_rounded, size: 22),
                  label: const Text(
                    'Tham Gia & Nộp Minh Chứng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Banner Header với Icon lớn, tên và mức thưởng
  Widget _buildHeroBanner(ThemeData theme, bool isDark, Color catColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [catColor.withValues(alpha: 0.25), theme.cardColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [catColor.withValues(alpha: 0.12), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: catColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: catColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  getIconData(challenge.icon),
                  size: 32,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        challenge.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mức tài trợ vào Quỹ:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '+${challenge.formattedRewardAmount}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '💡 Số tiền được nhà tài trợ chuyển thẳng vào Sổ Quỹ từ thiện ngay khi Admin duyệt minh chứng của bạn.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Lưới 3 ô thống kê
  Widget _buildQuickStatTriplets(ThemeData theme, Color catColor) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoTile(
            theme,
            icon: Icons.calendar_today_rounded,
            color: catColor,
            title: 'Chu kỳ',
            value: 'Hằng ngày',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            theme,
            icon: Icons.verified_user_rounded,
            color: AppColors.primary,
            title: 'Xác thực',
            value: 'AI OCR + Admin',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            theme,
            icon: Icons.favorite_rounded,
            color: AppColors.accent,
            title: 'Ý nghĩa',
            value: 'Gây quỹ 100M',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Thể lệ và các bước tham gia
  Widget _buildRulesCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rule_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Thể Lệ & Các Bước Thực Hiện',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 14),
            _buildStepRow(
              number: '1',
              title: 'Thực hiện hành động',
              desc: 'Hoàn thành thử thách thực tế (dậy sớm, dạy học, giải thuật toán, chạy bộ).',
            ),
            _buildStepRow(
              number: '2',
              title: 'Chụp ảnh minh chứng rõ nét',
              desc: 'Ghi lại khoảnh khắc kèm đồng hồ hoặc ứng dụng tracking thể thao.',
            ),
            _buildStepRow(
              number: '3',
              title: 'AI OCR quét tự động',
              desc: 'Google ML Kit bóc tách mốc giờ, ngày tháng và đối chiếu sơ bộ.',
            ),
            _buildStepRow(
              number: '4',
              title: 'Admin phê duyệt & Giải ngân',
              desc: 'Admin duyệt minh chứng, tiền tài trợ tự động cộng vào Quỹ Thiện Nguyện.',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Tiêu chuẩn ảnh chụp cho AI OCR
  Widget _buildAiOcrStandardCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tiêu Chuẩn Ảnh Chụp (AI OCR)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildCheckmarkItem(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              text: 'Đồng hồ hoặc mốc giờ phải hiển thị rõ nét (dạng 05:42, 5:42 AM hoặc 5h18).',
            ),
            _buildCheckmarkItem(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              text: 'Đảm bảo đủ ánh sáng, không bị bóng mờ hay chói lóa đèn bàn.',
            ),
            _buildCheckmarkItem(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              text: 'Ảnh chụp trực tiếp từ Camera, không chụp lại màn hình thiết bị khác.',
            ),
            _buildCheckmarkItem(
              icon: Icons.cancel_rounded,
              color: AppColors.danger,
              text: 'Không chỉnh sửa, che mờ hoặc cắt ghép mốc thời gian.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckmarkItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Danh sách hoàn thành gần đây
  Widget _buildRecentCompletionsCard(ThemeData theme) {
    final recentMembers = [
      {'name': 'Nguyễn Văn Huỳnh', 'time': '5:45 hôm nay', 'status': 'Đã duyệt (+20k)'},
      {'name': 'Nguyễn Trung Kiên', 'time': '5:50 hôm nay', 'status': 'Đã duyệt (+20k)'},
      {'name': 'Lê Anh Tuấn', 'time': 'Hôm qua', 'status': 'Đã duyệt (+20k)'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Thành Viên Vừa Hoàn Thành',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentMembers.length,
              separatorBuilder: (_, _) => const Divider(height: 14),
              itemBuilder: (context, index) {
                final m = recentMembers[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        m['name']![0],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['name']!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            m['time']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      m['status']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
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
