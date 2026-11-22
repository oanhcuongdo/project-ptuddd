import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DisciplineTab extends StatelessWidget {
  const DisciplineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 48,
                    color: AppTheme.streakOrange,
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chuỗi Kỷ Luật (Streak)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '3 ngày liên tiếp rèn luyện',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mục tiêu hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.record_voice_over,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text('Thực hành hội thoại 15 phút'),
                  subtitle: Text('Chủ đề: Giới thiệu bản thân & sở thích'),
                  trailing: Icon(Icons.check_box_outline_blank),
                ),
                Divider(),
                ListTile(
                  leading: Icon(
                    Icons.menu_book,
                    color: AppTheme.secondaryColor,
                  ),
                  title: Text('Lưu 3 từ vựng mới vào Sổ tay'),
                  subtitle: Text('Tra cứu và lưu từ mới từ phòng chat'),
                  trailing: Icon(Icons.check_box_outline_blank),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
