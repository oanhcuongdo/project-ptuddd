import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống Kê Tiến Độ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.insights_outlined, size: 64, color: Colors.indigo),
            SizedBox(height: 16),
            Text('Biểu Đồ Học Tập fl_chart & Bảng Xếp Hạng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Đang phát triển theo phân công Issue #33 của Bảo'),
          ],
        ),
      ),
    );
  }
}
