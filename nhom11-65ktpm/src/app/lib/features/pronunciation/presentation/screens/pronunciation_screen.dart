import 'package:flutter/material.dart';

class PronunciationScreen extends StatelessWidget {
  const PronunciationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện Phát Âm')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.mic_none_outlined, size: 64, color: Colors.redAccent),
            SizedBox(height: 16),
            Text('Chấm Phát Âm Offline & Azure Speech', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Đang phát triển theo phân công Issue #15 của Khanh'),
          ],
        ),
      ),
    );
  }
}
