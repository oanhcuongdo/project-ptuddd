import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChaiLish - 学中文',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppConstants.loginRoute),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Streak & Progress Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Xin chào, Học viên!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mục tiêu: 15 phút học mỗi ngày',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.local_fire_department, color: Colors.amber, size: 28),
                      SizedBox(width: 4),
                      Text(
                        '3 ngày',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Tính Năng Cốt Lõi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Feature Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildFeatureCard(
                  context,
                  title: 'Bản Đồ Lộ Trình',
                  subtitle: 'HSK 1 - HSK 2',
                  icon: Icons.map_outlined,
                  color: Colors.blue,
                  route: AppConstants.roadmapRoute,
                ),
                _buildFeatureCard(
                  context,
                  title: 'Chấm Phát Âm AI',
                  subtitle: 'Thanh điệu & Pinyin',
                  icon: Icons.mic_none_outlined,
                  color: Colors.redAccent,
                  route: AppConstants.pronunciationRoute,
                ),
                _buildFeatureCard(
                  context,
                  title: 'Luyện Viết Hán Tự',
                  subtitle: 'Thứ tự nét chuẩn',
                  icon: Icons.brush_outlined,
                  color: Colors.purple,
                  route: AppConstants.writingRoute,
                ),
                _buildFeatureCard(
                  context,
                  title: 'Flashcard SM-2',
                  subtitle: 'Ôn tập ngắt quãng',
                  icon: Icons.style_outlined,
                  color: Colors.amber.shade800,
                  route: AppConstants.flashcardRoute,
                ),
                _buildFeatureCard(
                  context,
                  title: 'Trợ Lý AI Ôn Bài',
                  subtitle: 'Hội thoại & Ngữ pháp',
                  icon: Icons.smart_toy_outlined,
                  color: Colors.teal,
                  route: AppConstants.aiChatRoute,
                ),
                _buildFeatureCard(
                  context,
                  title: 'Thống Kê Tiến Độ',
                  subtitle: 'Biểu đồ & Xếp hạng',
                  icon: Icons.insights_outlined,
                  color: Colors.indigo,
                  route: AppConstants.statisticsRoute,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
