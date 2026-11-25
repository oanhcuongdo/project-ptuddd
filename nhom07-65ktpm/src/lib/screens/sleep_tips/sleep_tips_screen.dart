import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SleepTipsScreen extends StatelessWidget {
  const SleepTipsScreen({super.key});

  final List<Map<String, String>> _tips = const [
    {
      'title': 'Kỹ thuật thở 4-7-8 giúp thư giãn sâu',
      'category': 'Thư giãn',
      'content': 'Hít vào bằng mũi trong 4 giây, nín thở trong 7 giây và thở ra từ từ bằng miệng trong 8 giây. Thực hiện 4 chu kỳ giúp kích hoạt hệ thần kinh phó giao cảm và làm chậm nhịp tim.',
    },
    {
      'title': 'Vệ sinh giấc ngủ: Kiểm soát ánh sáng xanh',
      'category': 'Vệ sinh giấc ngủ',
      'content': 'Ánh sáng xanh từ màn hình smartphone và máy tính ức chế hormone Melatonin. Hãy bật chế độ Night Light (ánh sáng vàng) hoặc ngừng dùng thiết bị ít nhất 30 phút trước khi ngủ.',
    },
    {
      'title': 'Nhiệt độ phòng ngủ tối ưu',
      'category': 'Môi trường',
      'content': 'Nhiệt độ phòng ngủ lý tưởng cho hầu hết mọi người dao động từ 20°C đến 24°C. Nhiệt độ quá nóng sẽ làm gián đoạn giấc ngủ sâu (REM).',
    },
    {
      'title': 'Giới hạn Caffeine vào buổi chiều',
      'category': 'Dinh dưỡng',
      'content': 'Caffeine có thời gian bán hủy từ 5 đến 7 tiếng. Uống cà phê sau 14h chiều có thể làm giảm chất lượng giấc ngủ ngay cả khi bạn vẫn có thể ngủ được.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thư Viện Cải Thiện Giấc Ngủ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentIndigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tip['category']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tip['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tip['content']!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
