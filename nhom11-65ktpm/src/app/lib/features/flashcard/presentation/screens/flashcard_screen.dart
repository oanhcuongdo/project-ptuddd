import 'package:flutter/material.dart';

class FlashcardScreen extends StatelessWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcard Ôn Tập')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.style_outlined, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text('Ôn Tập Ngắt Quãng SM-2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Đang phát triển theo phân công Issue #20 của Hoa'),
          ],
        ),
      ),
    );
  }
}
