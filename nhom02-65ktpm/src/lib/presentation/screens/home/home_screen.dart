import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Thông báo',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
            tooltip: 'Hồ sơ',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner giới thiệu nhóm & đề tài
          Card(
            color: theme.colorScheme.primaryContainer.withAlpha(80),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Dự Án Cuối Kỳ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NutriTrack AI',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kiến trúc Layered Architecture (Presentation - Application - Domain - Data). Cấu hình Dependency Injection với GetIt.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Phân Hệ Chức Năng Dự Án',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Danh sách các module phân công theo từng thành viên
          _buildFeatureCard(
            context: context,
            title: '1. Quét Món Ăn Bằng Gemini AI',
            subtitle: 'Chụp ảnh món ăn, phân tích dinh dưỡng & màn hình xác nhận',
            assignee: 'Phùng Thành An (Issue #7)',
            icon: Icons.camera_alt_outlined,
            color: Colors.teal,
          ),
          _buildFeatureCard(
            context: context,
            title: '2. Nhật Ký Ăn Uống & Ăn Lại',
            subtitle: 'Theo dõi 4 bữa ăn hằng ngày, xóa mềm Tombstone kèm Undo',
            assignee: 'Phùng Thành An (Issue #5)',
            icon: Icons.menu_book_rounded,
            color: Colors.green,
          ),
          _buildFeatureCard(
            context: context,
            title: '3. Tài Khoản & Mục Tiêu',
            subtitle: 'Đăng ký, đăng nhập Firebase Auth, chọn mục tiêu ban đầu',
            assignee: 'Nguyễn Hoàng Anh (Issue #4)',
            icon: Icons.person_rounded,
            color: Colors.blue,
          ),
          _buildFeatureCard(
            context: context,
            title: '4. Gợi Ý & Gọi Món Thông Minh',
            subtitle: 'Tips khoa học theo mục tiêu và quét thực đơn quán ăn',
            assignee: 'Nguyễn Hoàng Anh (Issue #8)',
            icon: Icons.tips_and_updates_outlined,
            color: Colors.amber.shade800,
          ),
          _buildFeatureCard(
            context: context,
            title: '5. Thống Kê Thói Quen (fl_chart)',
            subtitle: 'Biểu đồ trực quan và báo cáo tiến bộ so sánh theo tuần',
            assignee: 'Võ Mạnh Thắng (Issue #9)',
            icon: Icons.bar_chart_rounded,
            color: Colors.purple,
          ),
          _buildFeatureCard(
            context: context,
            title: '6. Thử Thách & Nhắc Nhở',
            subtitle: 'Chuỗi Streak thói quen và thông báo cục bộ đúng giờ',
            assignee: 'Đặng Xuân Minh (Issue #10)',
            icon: Icons.emoji_events_outlined,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String assignee,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(40),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Phụ trách: $assignee',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
