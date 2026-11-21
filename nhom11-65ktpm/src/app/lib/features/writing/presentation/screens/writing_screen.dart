import 'package:flutter/material.dart';

class WritingScreen extends StatelessWidget {
  const WritingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện Viết Hán Tự')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.brush_outlined, size: 64, color: Colors.purple),
            SizedBox(height: 16),
            Text('Khung Ô Chữ & Kiểm Tra Thứ Tự Nét', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Đang phát triển theo phân công Issue #26 của Đệ'),
          ],
        ),
      ),
    );
  }
}
