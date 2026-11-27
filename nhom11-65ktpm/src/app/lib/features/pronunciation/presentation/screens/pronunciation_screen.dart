import 'package:flutter/material.dart';
import 'pronunciation_practice_screen.dart';

class PronunciationScreen extends StatelessWidget {
  final String? lessonId;
  final String? word;

  const PronunciationScreen({
    super.key,
    this.lessonId,
    this.word,
  });

  @override
  Widget build(BuildContext context) {
    return PronunciationPracticeScreen(
      lessonId: lessonId,
      initialWord: word,
      targetHanzi: word ?? '你好',
      targetPinyin: word != null ? '' : 'nǐ hǎo',
      meaning: word != null ? 'Từ vựng luyện tập' : 'Xin chào',
    );
  }
}
