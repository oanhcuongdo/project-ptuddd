import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../scoring/phonemes.dart';
import '../scoring/pronunciation_scorer.dart';
import 'practice_screen.dart';

/// Xem lại một lượt nói cũ: phân tích từng âm và gợi ý như lúc vừa nói xong.
/// Pop trả về id bài học nếu người học nhấn "Luyện bài" trong một gợi ý.
class AttemptDetailScreen extends StatefulWidget {
  final String expected;
  final String recognized;
  final double confidence;
  final DateTime at;

  const AttemptDetailScreen(
      {super.key,
      required this.expected,
      required this.recognized,
      required this.confidence,
      required this.at});

  @override
  State<AttemptDetailScreen> createState() => _AttemptDetailScreenState();
}

class _AttemptDetailScreenState extends State<AttemptDetailScreen> {
  final _tts = FlutterTts();
  // ponytail: chấm lại offline từ văn bản đã lưu (kết quả xác định nên khớp lúc
  // nói); lượt chấm bằng Azure sẽ hiện kết quả offline. Muốn đúng 100% thì lưu
  // JSON kết quả vào attempts (cần nâng DB lên v2).
  late final _result =
      scorePronunciation(widget.expected, widget.recognized, confidence: widget.confidence);

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.4);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String get _when {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = widget.at;
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết lượt nói')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_when, textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Text(widget.expected, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          Text(ipaOfText(widget.expected),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
          Center(
            child: TextButton.icon(
              onPressed: () => _tts.speak(widget.expected),
              icon: const Icon(Icons.volume_up),
              label: const Text('Nghe mẫu'),
            ),
          ),
          Text('Nghe được: "${widget.recognized}"',
              textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const Divider(height: 32),
          FeedbackView(result: _result, currentLessonId: '', speak: _tts.speak),
        ],
      ),
    );
  }
}
