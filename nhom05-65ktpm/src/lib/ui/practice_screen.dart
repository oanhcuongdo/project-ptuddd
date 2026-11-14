import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../app_state.dart';
import '../data/lessons.dart';
import '../scoring/feedback.dart';
import '../scoring/phonemes.dart';
import '../scoring/pronunciation_scorer.dart';

class PracticeScreen extends StatefulWidget {
  final Lesson lesson;
  final int sessionId;
  final Stopwatch watch;

  const PracticeScreen(
      {super.key, required this.lesson, required this.sessionId, required this.watch});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _stt = SpeechToText();
  final _tts = FlutterTts();
  bool _sttReady = false;
  String? _sttError;
  int _index = 0;
  String _heard = '';
  PronunciationResult? _result;

  String get _target => widget.lesson.items[_index];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.4);
    _initStt();
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() => _sttError = switch (e.errorMsg) {
              'error_speech_timeout' || 'error_no_match' =>
                'Không nghe rõ giọng nói. Hãy nói to, gần micro hơn rồi thử lại.',
              'error_network' || 'error_network_timeout' || 'error_server' =>
                'Lỗi mạng. Nhận dạng giọng nói cần kết nối Internet.',
              'error_audio' || 'error_permission' => 'Không truy cập được micro. Hãy kiểm tra quyền.',
              _ => 'Lỗi nhận dạng: ${e.errorMsg}. Hãy thử lại.',
            });
      },
      onStatus: (_) {
        if (mounted) setState(() {});
      },
    );
    if (mounted) {
      setState(() {
        _sttReady = ok;
        if (!ok) _sttError = 'Thiết bị không hỗ trợ nhận dạng giọng nói hoặc chưa cấp quyền micro.';
      });
    }
  }

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    await _tts.stop();
    setState(() {
      _heard = '';
      _result = null;
      _sttError = null;
    });
    await _stt.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        localeId: 'en_US',
        partialResults: true,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        // Deliberately no contextualPhrases: biasing the recognizer toward
        // the target text would hide the learner's mistakes.
      ),
    );
  }

  Future<void> _onResult(SpeechRecognitionResult r) async {
    if (!mounted) return;
    setState(() => _heard = r.recognizedWords);
    if (!r.finalResult) return;
    final result = scorePronunciation(_target, r.recognizedWords,
        confidence: r.hasConfidenceRating ? r.confidence : 0);
    setState(() => _result = result);
    if (r.recognizedWords.trim().isEmpty) return;
    final state = context.read<AppState>();
    await state.db.saveAttempt(state.user!.id, widget.sessionId, result);
    // Persist time so far in case the app is killed mid-session.
    await state.db.endSession(widget.sessionId, widget.watch.elapsed.inSeconds);
  }

  void _go(int delta) => setState(() {
        _index = (_index + delta) % widget.lesson.items.length;
        _heard = '';
        _result = null;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listening = _stt.isListening;
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_index + 1}/${widget.lesson.items.length}', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Text(_target, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          Text(ipaOfText(_target),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => _tts.speak(_target),
              icon: const Icon(Icons.volume_up),
              label: const Text('Nghe mẫu'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FloatingActionButton.large(
              heroTag: 'mic',
              tooltip: listening ? 'Dừng' : 'Nhấn và đọc to',
              backgroundColor: listening ? theme.colorScheme.error : null,
              onPressed: !_sttReady ? null : (listening ? _stt.stop : _listen),
              child: Icon(listening ? Icons.stop : Icons.mic),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            listening ? 'Đang nghe…' : 'Nhấn micro và đọc to câu trên',
            textAlign: TextAlign.center,
          ),
          if (_heard.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Nghe được: "$_heard"',
                  textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            ),
          if (_sttError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_sttError!,
                  textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (_result != null) ...[
            const Divider(height: 32),
            FeedbackView(
              result: _result!,
              currentLessonId: widget.lesson.id,
              speak: _tts.speak,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                  onPressed: () => _go(-1), icon: const Icon(Icons.arrow_back), label: const Text('Trước')),
              FilledButton.icon(
                  onPressed: () => _go(1), icon: const Icon(Icons.arrow_forward), label: const Text('Tiếp')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Score, per-phoneme highlighting, error list and improvement exercises.
class FeedbackView extends StatelessWidget {
  final PronunciationResult result;
  final String currentLessonId;
  final Future<dynamic> Function(String) speak;

  const FeedbackView(
      {super.key, required this.result, required this.currentLessonId, required this.speak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.score >= 75
        ? Colors.green
        : result.score >= 50
            ? Colors.orange
            : theme.colorScheme.error;
    final ok = theme.colorScheme.onSurface;
    final suggestions = suggestionsFor(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                    value: result.score / 100, strokeWidth: 7, color: color,
                    backgroundColor: color.withValues(alpha: 0.2)),
                Text('${result.score}', style: theme.textTheme.headlineSmall),
              ]),
            ),
            const SizedBox(width: 16),
            Text(verdict(result.score), style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        Text('Phân tích từng âm (đỏ = sai):', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final w in result.words)
              Column(children: [
                Text(w.word,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: w.score == 100 ? ok : theme.colorScheme.error,
                        fontWeight: FontWeight.bold)),
                Text.rich(TextSpan(children: [
                  const TextSpan(text: '/'),
                  for (var i = 0; i < w.phonemes.length; i++)
                    TextSpan(
                      text: ipa(w.phonemes[i]),
                      style: w.correct[i]
                          ? null
                          : TextStyle(
                              color: theme.colorScheme.error,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold),
                    ),
                  const TextSpan(text: '/'),
                ])),
                Text('${w.score}', style: theme.textTheme.labelSmall),
              ]),
          ],
        ),
        if (result.errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final e in result.errors)
            Text('• ${e.word}: ${e.describe}', style: theme.textTheme.bodyMedium),
        ],
        for (final s in suggestions)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 ${s.title}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(s.tip),
                  if (s.practiceWords.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Luyện cặp từ (nhấn để nghe):', style: theme.textTheme.labelLarge),
                    Wrap(spacing: 8, children: [
                      for (final p in s.practiceWords)
                        ActionChip(label: Text(p), onPressed: () => speak(p.replaceAll('–', ','))),
                    ]),
                  ],
                  if (s.lessonId != currentLessonId)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, s.lessonId),
                        child: Text('Luyện bài "${lessonById(s.lessonId).title}"'),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
