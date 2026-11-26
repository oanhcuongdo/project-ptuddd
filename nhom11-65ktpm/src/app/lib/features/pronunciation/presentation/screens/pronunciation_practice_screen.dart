import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/models/pronunciation.dart';
import '../../../../core/contracts/pronunciation_scorer.dart';
import '../../../../core/contracts/speech_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

/// Man hinh luyen phat am va xem phan hoi chi tiet chuan Liquid Glass UI. Chu so huu: Khanh (#15)
class PronunciationPracticeScreen extends ConsumerStatefulWidget {
  final String targetHanzi;
  final String targetPinyin;
  final String meaning;

  const PronunciationPracticeScreen({
    super.key,
    this.targetHanzi = '你好',
    this.targetPinyin = 'nǐ hǎo',
    this.meaning = 'Xin chào',
  });

  @override
  ConsumerState<PronunciationPracticeScreen> createState() => _PronunciationPracticeScreenState();
}

class _PracticeWordItem {
  final String hanzi;
  final String pinyin;
  final String meaning;
  const _PracticeWordItem(this.hanzi, this.pinyin, this.meaning);
}

class _PronunciationPracticeScreenState extends ConsumerState<PronunciationPracticeScreen> {
  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isAssessing = false;
  bool _isPlayingTts = false;
  DateTime? _lastTtsTap;
  PronunciationResult? _result;
  double _currentAmplitude = 0.0;
  double _maxAmplitudeObserved = 0.0;
  String _recognizedWords = '';
  DateTime? _recordingStartedAt;
  Timer? _silenceTimer;
  Timer? _speechSilenceTimer;
  StreamSubscription<double>? _ampSub;
  bool _voiceDetected = false;

  late int _currentWordIndex;
  late List<_PracticeWordItem> _words;

  @override
  void initState() {
    super.initState();
    _words = [
      _PracticeWordItem(widget.targetHanzi, widget.targetPinyin, widget.meaning),
      const _PracticeWordItem('谢谢', 'xiè xie', 'Cảm ơn'),
      const _PracticeWordItem('再见', 'zài jiàn', 'Tạm biệt'),
      const _PracticeWordItem('很好', 'hěn hǎo', 'Rất tốt'),
      const _PracticeWordItem('朋友', 'péng you', 'Bạn bè'),
    ];
    _currentWordIndex = 0;

    // Khởi động tuần tự (staggered warm-up) Loa TTS và Mic STT trong màn hình chờ
    // Giúp triệt tiêu xung đột AudioTrack / AudioRecord trên Android Emulator, tránh tiếng nổ rè
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(ttsServiceProvider).initialize();
        // Giãn cách 300ms để AudioTrack DAC ổn định hoàn toàn trước khi mở AudioRecord
        await Future.delayed(const Duration(milliseconds: 300));
        await ref.read(speechRecognizerProvider).initialize();
        // Cho Audio HAL ổn định thêm 150ms sau khi cả TTS + STT đã sẵn sàng
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (_) {}
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    });
  }

  _PracticeWordItem get _currentWord => _words[_currentWordIndex];

  void _nextWord() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _speechSilenceTimer?.cancel();
    _speechSilenceTimer = null;
    _ampSub?.cancel();
    _ampSub = null;
    if (_isRecording) {
      ref.read(speechRecognizerProvider).stop();
      ref.read(voiceRecorderProvider).cancel();
    }
    if (_isPlayingTts) {
      ref.read(ttsServiceProvider).stop();
    }
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _words.length;
      _result = null;
      _recognizedWords = '';
      _currentAmplitude = 0.0;
      _maxAmplitudeObserved = 0.0;
      _isRecording = false;
      _isPlayingTts = false;
      _voiceDetected = false;
    });
  }

  void _prevWord() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _speechSilenceTimer?.cancel();
    _speechSilenceTimer = null;
    _ampSub?.cancel();
    _ampSub = null;
    if (_isRecording) {
      ref.read(speechRecognizerProvider).stop();
      ref.read(voiceRecorderProvider).cancel();
    }
    if (_isPlayingTts) {
      ref.read(ttsServiceProvider).stop();
    }
    setState(() {
      _currentWordIndex = (_currentWordIndex - 1 + _words.length) % _words.length;
      _result = null;
      _recognizedWords = '';
      _currentAmplitude = 0.0;
      _maxAmplitudeObserved = 0.0;
      _isRecording = false;
      _isPlayingTts = false;
      _voiceDetected = false;
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speechSilenceTimer?.cancel();
    _ampSub?.cancel();
    try {
      ref.read(speechRecognizerProvider).stop();
    } catch (_) {}
    try {
      ref.read(voiceRecorderProvider).cancel();
    } catch (_) {}
    try {
      ref.read(ttsServiceProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  void _startSilenceTimer({required VoidCallback onTimeout}) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 12), onTimeout);
  }

  Future<void> _playTts(TtsService tts, {bool slow = false}) async {
    final now = DateTime.now();
    if (_isPlayingTts) return;
    if (_lastTtsTap != null && now.difference(_lastTtsTap!).inMilliseconds < 400) {
      return;
    }
    _lastTtsTap = now;
    setState(() => _isPlayingTts = true);
    try {
      await tts.speak(_currentWord.hanzi, slow: slow);
    } catch (_) {}
    // Luôn nhả nút sau thời lượng phát của từ (khoảng 1.1s, hoặc 1.6s nếu đọc chậm)
    Future.delayed(Duration(milliseconds: slow ? 1600 : 1100), () {
      if (mounted) {
        setState(() => _isPlayingTts = false);
      }
    });
  }

  Future<void> _stopAndAssess({
    required SpeechRecognizer speechRecognizer,
    required VoiceRecorder voiceRecorder,
    required PinyinService pinyinService,
    required PronunciationScorer scorer,
  }) async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _speechSilenceTimer?.cancel();
    _speechSilenceTimer = null;
    _ampSub?.cancel();
    _ampSub = null;
    if (!_isRecording && !_isAssessing) return;

    setState(() {
      _isRecording = false;
      _isAssessing = true;
    });

    Recording? realRecording;
    try {
      realRecording = await voiceRecorder.stop();
    } catch (_) {}

    try {
      await speechRecognizer.stop();
      // Đợi một khoảng ngắn (350ms) để STT xử lý và hoàn tất phát sự kiện onResult cuối cùng
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } catch (_) {}

    final duration = _recordingStartedAt != null
        ? DateTime.now().difference(_recordingStartedAt!)
        : (realRecording?.duration ?? Duration.zero);
    _recordingStartedAt = null;
    final recording = realRecording ?? Recording(path: null, duration: duration);

    // Nếu bấm dừng ngay khi vừa dứt lời, đợi thêm 250ms nếu micro từng phát hiện có tiếng nói
    if (_recognizedWords.trim().isEmpty && _voiceDetected) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    String recognizedText = _recognizedWords.trim();

    String recognizedPinyin = '';
    if (recognizedText.isNotEmpty) {
      if (RegExp(r'[a-zA-Z]').hasMatch(recognizedText) && !RegExp(r'[\u4e00-\u9fff]').hasMatch(recognizedText)) {
        recognizedPinyin = recognizedText;
      } else {
        try {
          recognizedPinyin = await pinyinService.toPinyin(recognizedText);
        } catch (_) {}
        if (recognizedPinyin.isEmpty && recognizedText == _currentWord.hanzi) {
          recognizedPinyin = _currentWord.pinyin;
        }
      }
    }

    final res = await scorer.assess(
      referenceHanzi: _currentWord.hanzi,
      referencePinyin: _currentWord.pinyin,
      recording: recording,
      recognizedPinyin: recognizedPinyin.isNotEmpty ? recognizedPinyin : null,
      recognizedText: recognizedText.isNotEmpty ? recognizedText : null,
    );

    // Xoá file âm thanh tạm sau khi đã gửi đi chấm
    if (recording.path != null) {
      try {
        final f = File(recording.path!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _result = res;
        _isAssessing = false;
      });
    }
  }

  Future<void> _testPinyinDirectly(
    String testPinyin, {
    required PronunciationScorer scorer,
  }) async {
    setState(() {
      _isAssessing = true;
      _recognizedWords = testPinyin;
    });

    final res = await scorer.assess(
      referenceHanzi: _currentWord.hanzi,
      referencePinyin: _currentWord.pinyin,
      recording: const Recording(path: null, duration: Duration(milliseconds: 1200)),
      recognizedPinyin: testPinyin,
      recognizedText: testPinyin,
    );

    if (mounted) {
      setState(() {
        _result = res;
        _isAssessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const GlassScaffold(
        appBar: GlassAppBar(
          title: Text('Luyện Phát Âm'),
        ),
        body: Center(
          child: GlassCard(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Đang chuẩn bị âm thanh & micro...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sẵn sàng phát âm và nhận diện không gián đoạn',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cloud,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tts = ref.watch(ttsServiceProvider);
    final scorer = ref.watch(pronunciationScorerProvider);
    final speechRecognizer = ref.watch(speechRecognizerProvider);
    final voiceRecorder = ref.watch(voiceRecorderProvider);
    final pinyinService = ref.watch(pinyinServiceProvider);
    final mode = ref.watch(scoringModeProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Luyện Phát Âm'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  ref.read(scoringModeProvider.notifier).set(
                    mode == ScoringMode.preferOnline ? ScoringMode.offlineOnly : ScoringMode.preferOnline,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: (mode == ScoringMode.preferOnline ? AppColors.infoBlue : AppColors.warningOrange).withValues(alpha: 0.2),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    mode == ScoringMode.preferOnline ? 'Online (Azure)' : 'Offline',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 104, left: 20, right: 20, bottom: 32),
        child: Column(
          children: [
            if (mode == ScoringMode.offlineOnly)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.warningOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chế độ Offline: Kiểm tra đúng/sai chữ Hán. Chuyển sang Online (Azure) để chấm chi tiết thanh điệu & âm phổ.',
                        style: TextStyle(fontSize: 12, color: AppColors.cloud),
                      ),
                    ),
                  ],
                ),
              ),

            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _currentWordIndex > 0 ? _prevWord : null,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        tooltip: 'Từ trước',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: ShapeDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Từ ${_currentWordIndex + 1} / ${_words.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentWordIndex < _words.length - 1 ? _nextWord : null,
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        tooltip: 'Từ tiếp theo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentWord.pinyin,
                    style: const TextStyle(fontSize: 22, color: AppColors.cloud, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentWord.hanzi,
                    style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentWord.meaning,
                    style: const TextStyle(fontSize: 16, color: AppColors.cloud),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      GlassButton(
                        onPressed: _isPlayingTts ? null : () => _playTts(tts),
                        icon: _isPlayingTts ? Icons.graphic_eq : Icons.volume_up,
                        label: _isPlayingTts ? 'Đang đọc...' : 'Nghe mẫu',
                      ),
                      GlassButton(
                        onPressed: _isPlayingTts ? null : () => _playTts(tts, slow: true),
                        icon: Icons.speed,
                        label: 'Đọc chậm',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isRecording || _recognizedWords.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _recognizedWords.isNotEmpty
                      ? AppColors.jadeGreen.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _recognizedWords.isNotEmpty
                        ? AppColors.jadeGreen
                        : AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _recognizedWords.isNotEmpty ? Icons.record_voice_over : Icons.hearing,
                          color: _recognizedWords.isNotEmpty ? AppColors.jadeGreen : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _recognizedWords.isNotEmpty ? 'ĐÃ NHẬN DIỆN ĐƯỢC' : 'ĐANG LẮNG NGHE GIỌNG BẠN...',
                          style: TextStyle(
                            color: _recognizedWords.isNotEmpty ? AppColors.jadeGreen : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _recognizedWords.isNotEmpty
                          ? '"$_recognizedWords"'
                          : 'Hãy đọc to từ: ${_currentWord.hanzi} (${_currentWord.pinyin})',
                      style: TextStyle(
                        fontSize: _recognizedWords.isNotEmpty ? 24 : 14,
                        fontWeight: _recognizedWords.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                        color: _recognizedWords.isNotEmpty ? AppColors.slate : AppColors.cloud,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            if (_isRecording)
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, color: AppColors.errorRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Đang thu âm...',
                                style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (_recognizedWords.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ': "$_recognizedWords"',
                                    style: const TextStyle(color: AppColors.slate, fontSize: 12, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _currentAmplitude,
                              backgroundColor: AppColors.errorRed.withValues(alpha: 0.2),
                              color: AppColors.errorRed,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: _isAssessing
                  ? null
                  : () async {
                      if (_isRecording) {
                        await _stopAndAssess(
                          speechRecognizer: speechRecognizer,
                          voiceRecorder: voiceRecorder,
                          pinyinService: pinyinService,
                          scorer: scorer,
                        );
                      } else {
                        _recognizedWords = '';
                        _maxAmplitudeObserved = 0.0;
                        _recordingStartedAt = DateTime.now();

                        setState(() {
                          _isRecording = true;
                          _result = null;
                          _currentAmplitude = 0.15;
                        });

                        _speechSilenceTimer?.cancel();
                        _speechSilenceTimer = null;
                        _voiceDetected = false;

                        _startSilenceTimer(
                          onTimeout: () => _stopAndAssess(
                            speechRecognizer: speechRecognizer,
                            voiceRecorder: voiceRecorder,
                            pinyinService: pinyinService,
                            scorer: scorer,
                          ),
                        );

                        // Bat dau ghi am WAV qua RealVoiceRecorder (cho ket qua online Azure #14)
                        try {
                          await voiceRecorder.start();
                          _ampSub?.cancel();
                          _ampSub = voiceRecorder.amplitude.listen((amp) {
                            if (mounted) {
                              setState(() {
                                _currentAmplitude = amp;
                                if (amp > _maxAmplitudeObserved) {
                                  _maxAmplitudeObserved = amp;
                                }
                              });
                            }
                          });
                        } catch (e) {
                          debugPrint('RealVoiceRecorder start error: $e');
                        }

                        try {
                          await speechRecognizer.listen(
                            onResult: (text, isFinal) {
                              if (text.isNotEmpty && mounted) {
                                setState(() {
                                  _recognizedWords = text;
                                });
                              }
                              if (isFinal && mounted && _isRecording) {
                                _speechSilenceTimer?.cancel();
                                _speechSilenceTimer = Timer(const Duration(milliseconds: 1800), () {
                                  if (mounted && _isRecording) {
                                    _stopAndAssess(
                                      speechRecognizer: speechRecognizer,
                                      voiceRecorder: voiceRecorder,
                                      pinyinService: pinyinService,
                                      scorer: scorer,
                                    );
                                  }
                                });
                              }
                            },
                            onSoundLevel: (amp) {
                              if (mounted) {
                                setState(() {
                                  _currentAmplitude = amp;
                                  if (amp > _maxAmplitudeObserved) {
                                    _maxAmplitudeObserved = amp;
                                  }
                                });
                                if (amp >= 0.16) {
                                  _voiceDetected = true;
                                  _speechSilenceTimer?.cancel();
                                  _speechSilenceTimer = Timer(const Duration(milliseconds: 2500), () {
                                    if (mounted && _isRecording) {
                                      _stopAndAssess(
                                        speechRecognizer: speechRecognizer,
                                        voiceRecorder: voiceRecorder,
                                        pinyinService: pinyinService,
                                        scorer: scorer,
                                      );
                                    }
                                  });
                                }
                              }
                            },
                            onError: (error) {
                              debugPrint('STT notice on emulator: $error');
                            },
                          );
                        } catch (e) {
                          debugPrint('Speech recognition error: $e');
                        }
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? AppColors.errorRed : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? AppColors.errorRed : AppColors.primary).withValues(alpha: _isRecording ? 0.5 : 0.25),
                      blurRadius: _isRecording ? 20 : 12,
                      spreadRadius: _isRecording ? 6 : 2,
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording ? 'Đang lắng nghe... Chạm nút để gửi hoặc dừng nói 2.5s' : 'Chạm vào micro để bắt đầu nói',
              style: const TextStyle(color: AppColors.cloud, fontSize: 13),
            ),

            if (kDebugMode && !_isRecording && !_isAssessing) ...[
              const SizedBox(height: 14),
              const Text('Kiểm tra nhanh bắt lỗi dấu Pinyin (Debug):', style: TextStyle(color: AppColors.cloud, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.jadeGreen),
                    label: const Text('nǐ hǎo (Chuẩn 100đ)', style: TextStyle(fontSize: 12)),
                    onPressed: () => _testPinyinDirectly('nǐ hǎo', scorer: scorer),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.errorRed),
                    label: const Text('ni háo (Sai cả 2 thanh)', style: TextStyle(fontSize: 12)),
                    onPressed: () => _testPinyinDirectly('ni háo', scorer: scorer),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.errorRed),
                    label: const Text('nĩ hào (Sai thanh 4)', style: TextStyle(fontSize: 12)),
                    onPressed: () => _testPinyinDirectly('nĩ hào', scorer: scorer),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warningOrange),
                    label: const Text('nỉ hao (Sai thanh nhẹ)', style: TextStyle(fontSize: 12)),
                    onPressed: () => _testPinyinDirectly('nỉ hao', scorer: scorer),
                  ),
                ],
              ),
            ],

            if (_isAssessing) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Đang phân tích phát âm...'),
            ],

            if (_result != null) ...[
              const SizedBox(height: 28),
              _buildFeedbackCard(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(PronunciationResult res) {
    Color scoreColor = AppColors.jadeGreen;
    if (res.overall < 60) {
      scoreColor = AppColors.errorRed;
    } else if (res.overall < 80) {
      scoreColor = AppColors.warningOrange;
    }

    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kết Quả Đánh Giá Chi Tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      'Nguồn: ${res.source == ScoringSource.online ? "Azure Speech (Online)" : "Engine Offline (Kiểm tra đúng/sai chữ)"}',
                      style: const TextStyle(color: AppColors.cloud, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: ShapeDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '${res.overall.toInt()} đ',
                  style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (res.overall == 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_off, color: AppColors.errorRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _recognizedWords.trim().isNotEmpty
                          ? 'Đã nhận diện âm "${_recognizedWords.trim()}" nhưng chưa khớp chính xác từ cần luyện (${_currentWord.hanzi}). Hãy thử đọc lại rõ ràng hơn!'
                          : 'Chưa nhận diện được phát âm tiếng Trung. Hãy thử nói to hơn gần micro máy tính hoặc kiểm tra cài đặt mic của máy ảo!',
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (res.recognizedText.isNotEmpty && res.recognizedText != _currentWord.hanzi)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Âm nhận diện được: "${res.recognizedText}"',
                        style: const TextStyle(fontSize: 13, color: AppColors.slate, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            _buildCoachAdviceBox(res),
            const Text(
              '4 Tiêu Chí Đánh Giá Chuẩn Quốc Tế:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildCriteriaProgress('1. Độ chính xác âm tiết (Accuracy)', res.accuracy, res.accuracy >= 80 ? 'Chuẩn xác' : 'Cần chú ý'),
            _buildCriteriaProgress('2. Thanh điệu ngữ âm (Tone)', res.tone, res.tone >= 80 ? 'Đúng cao độ' : 'Lệch thanh'),
            _buildCriteriaProgress('3. Độ trôi chảy (Fluency)', res.fluency, res.fluency >= 80 ? 'Tự nhiên' : 'Ngắt quãng'),
            _buildCriteriaProgress('4. Độ trọn vẹn từ (Completeness)', res.completeness, res.completeness >= 90 ? 'Đủ âm' : 'Thiếu từ'),
            const SizedBox(height: 16),
            const Text(
              'Phân Tích Giải Phẫu Từng Âm Tiết:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            for (final s in res.syllables) _buildSyllableDetailCard(s),
          ],
          if (_currentWordIndex < _words.length - 1) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                icon: Icons.navigate_next,
                label: 'Luyện từ tiếp theo: ${_words[_currentWordIndex + 1].hanzi}',
                onPressed: _nextWord,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoachAdviceBox(PronunciationResult res) {
    String advice;
    IconData icon;
    Color boxColor;

    if (res.overall >= 90) {
      advice = 'Xuất sắc! Phát âm rất chuẩn xác, khẩu hình và thanh điệu tự nhiên như người bản xứ.';
      icon = Icons.stars;
      boxColor = AppColors.jadeGreen;
    } else if (res.overall >= 75) {
      advice = 'Khá tốt! Bạn phát âm từ rõ ràng và người bản xứ hiểu được. Hãy chú ý giữ đúng trường độ thanh điệu để nói tự nhiên hơn.';
      icon = Icons.thumb_up_alt_outlined;
      boxColor = AppColors.primary;
    } else if (res.overall >= 50) {
      advice = 'Cần luyện thêm: Một số âm tiết bị lệch thanh mẫu hoặc thanh điệu. Hãy xem chi tiết phân tích từng phần bên dưới để điều chỉnh khẩu hình.';
      icon = Icons.lightbulb_outline;
      boxColor = AppColors.warningOrange;
    } else {
      advice = 'Hãy nghe mẫu đọc chậm, chú ý mở rộng khẩu hình miệng và đọc dứt khoát từng âm tiết để máy nhận diện rõ ràng hơn.';
      icon = Icons.info_outline;
      boxColor = AppColors.errorRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boxColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: boxColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: boxColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhận Xét Từ Trợ Lý AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: boxColor),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaProgress(String label, double score, String desc) {
    Color barColor = AppColors.jadeGreen;
    if (score < 60) {
      barColor = AppColors.errorRed;
    } else if (score < 80) {
      barColor = AppColors.warningOrange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Text(desc, style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text('${score.toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: barColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              backgroundColor: barColor.withValues(alpha: 0.15),
              color: barColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllableDetailCard(SyllableScore s) {
    Color cardBorder = AppColors.jadeGreen;
    String statusText = 'Chuẩn xác';
    if (s.status == SyllableStatus.error) {
      cardBorder = AppColors.errorRed;
      statusText = 'Sai âm';
    } else if (s.status == SyllableStatus.warn) {
      cardBorder = AppColors.warningOrange;
      statusText = 'Cần sửa';
    }

    final hasInitialError = s.errors.contains(PronunciationError.initial);
    final hasFinalError = s.errors.contains(PronunciationError.finalPart);
    final hasToneError = s.errors.contains(PronunciationError.tone);
    final isMissing = s.errors.contains(PronunciationError.missing);

    String tip = '';
    if (isMissing) {
      tip = 'Âm tiết bị bỏ sót khi đọc, hãy đọc to và trọn vẹn từ.';
    } else if (hasInitialError && hasToneError) {
      tip = 'Sai phụ âm đầu "${s.expected.initial}" và lệch thanh điệu thanh ${s.expected.tone}.';
    } else if (hasInitialError) {
      tip = 'Chú ý phụ âm đầu "${s.expected.initial}": chú ý khẩu hình và bật hơi đúng.';
    } else if (hasToneError) {
      tip = 'Chú ý thanh điệu: đây là thanh ${s.expected.tone}, kiểm tra cao độ chuẩn.';
    } else if (hasFinalError) {
      tip = 'Chú ý nguyên âm/vần "${s.expected.finalPart}": mở rộng khẩu hình miệng.';
    } else {
      tip = 'Phát âm chuẩn cả thanh mẫu, vận mẫu và thanh điệu!';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBorder.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    s.hanzi,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${s.expected.initial}${s.expected.finalPart}${s.expected.tone}',
                    style: const TextStyle(fontSize: 16, color: AppColors.cloud, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: ShapeDecoration(
                  color: cardBorder.withValues(alpha: 0.15),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '$statusText • ${s.score.toInt()}đ',
                  style: TextStyle(color: cardBorder, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPartColumn(
                  label: 'Thanh mẫu',
                  expected: s.expected.initial.isEmpty ? 'Ø' : s.expected.initial,
                  actual: s.actual?.initial.isEmpty == true ? 'Ø' : (s.actual?.initial ?? '—'),
                  isError: hasInitialError || isMissing,
                ),
                _buildPartColumn(
                  label: 'Vận mẫu',
                  expected: s.expected.finalPart,
                  actual: s.actual?.finalPart ?? '—',
                  isError: hasFinalError || isMissing,
                ),
                _buildPartColumn(
                  label: 'Thanh điệu',
                  expected: 'Thanh ${s.expected.tone}',
                  actual: s.actual != null ? 'Thanh ${s.actual!.tone}' : '—',
                  isError: hasToneError || isMissing,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                s.status == SyllableStatus.ok ? Icons.check_circle : Icons.tips_and_updates,
                size: 15,
                color: cardBorder,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(fontSize: 12, color: s.status == SyllableStatus.ok ? AppColors.jadeGreen : AppColors.slate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartColumn({
    required String label,
    required String expected,
    required String actual,
    required bool isError,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.cloud)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expected,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            if (isError) ...[
              const Icon(Icons.arrow_right_alt, size: 14, color: AppColors.errorRed),
              Text(
                actual,
                style: const TextStyle(fontSize: 13, color: AppColors.errorRed, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
