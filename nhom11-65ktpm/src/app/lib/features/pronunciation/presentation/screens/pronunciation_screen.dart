import 'package:flutter/material.dart';
import 'pronunciation_practice_screen.dart';

class PronunciationScreen extends StatelessWidget {
  const PronunciationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PronunciationPracticeScreen(
      targetHanzi: '你好',
      targetPinyin: 'nǐ hǎo',
      meaning: 'Xin chào',
    );
  }
}
