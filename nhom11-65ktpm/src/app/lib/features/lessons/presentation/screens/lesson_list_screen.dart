import 'package:flutter/material.dart';

class LessonListScreen extends StatelessWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh Sách Bài Học')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.book_outlined, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Danh Sách Bài Học HSK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Đang phát triển theo phân công Issue #19 của Hoa'),
          ],
        ),
      ),
    );
  }
}
