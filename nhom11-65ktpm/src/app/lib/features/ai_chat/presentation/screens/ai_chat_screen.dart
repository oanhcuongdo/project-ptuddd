import 'package:flutter/material.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ Lý AI Ôn Bài')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.smart_toy_outlined, size: 64, color: Colors.teal),
            SizedBox(height: 16),
            Text('Hội Thoại & Phân Tích Ngữ Pháp AI (Claude API)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Đang phát triển theo phân công Issue #9 của Phúc'),
          ],
        ),
      ),
    );
  }
}
