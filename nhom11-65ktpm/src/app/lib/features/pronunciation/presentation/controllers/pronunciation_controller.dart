import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/lesson_repository.dart';
import '../../../../core/contracts/models/learning_event.dart';
import '../../../../core/contracts/models/pronunciation.dart';
import '../../../../core/contracts/progress_service.dart';
import '../../../../core/contracts/pronunciation_scorer.dart';
import '../../../../core/contracts/speech_services.dart';

class PracticeWordItem {
  final String hanzi;
  final String pinyin;
  final String meaning;
  const PracticeWordItem(this.hanzi, this.pinyin, this.meaning);
}

class PronunciationState {
  final bool isInitializing;
  final bool isRecording;
  final bool isAssessing;
  final bool isPlayingTts;
  final double currentAmplitude;
  final double maxAmplitudeObserved;
  final String recognizedWords;
  final PronunciationResult? result;
  final int currentWordIndex;
  final List<PracticeWordItem> words;
  final String? errorMessage;
  final bool permissionDenied;

  const PronunciationState({
    this.isInitializing = true,
    this.isRecording = false,
    this.isAssessing = false,
    this.isPlayingTts = false,
    this.currentAmplitude = 0.0,
    this.maxAmplitudeObserved = 0.0,
    this.recognizedWords = '',
    this.result,
    this.currentWordIndex = 0,
    this.words = const [],
    this.errorMessage,
    this.permissionDenied = false,
  });

  PracticeWordItem get currentWord =>
      words.isNotEmpty && currentWordIndex < words.length
          ? words[currentWordIndex]
          : const PracticeWordItem('你好', 'nǐ hǎo', 'Xin chào');

  PronunciationState copyWith({
    bool? isInitializing,
    bool? isRecording,
    bool? isAssessing,
    bool? isPlayingTts,
    double? currentAmplitude,
    double? maxAmplitudeObserved,
    String? recognizedWords,
    PronunciationResult? result,
    bool clearResult = false,
    int? currentWordIndex,
    List<PracticeWordItem>? words,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? permissionDenied,
  }) {
    return PronunciationState(
      isInitializing: isInitializing ?? this.isInitializing,
      isRecording: isRecording ?? this.isRecording,
      isAssessing: isAssessing ?? this.isAssessing,
      isPlayingTts: isPlayingTts ?? this.isPlayingTts,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      maxAmplitudeObserved: maxAmplitudeObserved ?? this.maxAmplitudeObserved,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      result: clearResult ? null : (result ?? this.result),
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      words: words ?? this.words,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

class PronunciationController extends Notifier<PronunciationState> {
  StreamSubscription<double>? _ampSub;
  Timer? _silenceTimer;
  Timer? _speechSilenceTimer;
  DateTime? _recordingStartedAt;
  DateTime? _lastTtsTap;
  bool _voiceDetected = false;

  @override
  PronunciationState build() {
    ref.onDispose(_cleanupTimers);
    return const PronunciationState();
  }

  Future<void> init({
    String targetHanzi = '你好',
    String targetPinyin = 'nǐ hǎo',
    String meaning = 'Xin chào',
    String? lessonId,
    String? initialWord,
  }) async {
    var words = <PracticeWordItem>[
      PracticeWordItem(targetHanzi, targetPinyin, meaning),
      const PracticeWordItem('谢谢', 'xiè xie', 'Cảm ơn'),
      const PracticeWordItem('再见', 'zài jiàn', 'Tạm biệt'),
      const PracticeWordItem('很好', 'hěn hǎo', 'Rất tốt'),
      const PracticeWordItem('朋友', 'péng you', 'Bạn bè'),
    ];

    if (lessonId != null) {
      try {
        final lessons = await ref.read(lessonRepositoryProvider).lessons();
        final match = lessons.where((l) => l.code == lessonId || l.id.toString() == lessonId).firstOrNull;
        if (match != null && match.words.isNotEmpty) {
          words = match.words
              .map((w) => PracticeWordItem(w.hanzi, w.pinyin, (w.hanViet != null && w.hanViet!.isNotEmpty) ? w.hanViet! : 'Từ vựng'))
              .toList();
        }
      } catch (_) {}
    }

    var startIndex = 0;
    if (initialWord != null && initialWord.isNotEmpty) {
      final idx = words.indexWhere((w) => w.hanzi == initialWord);
      if (idx >= 0) {
        startIndex = idx;
      } else {
        words.insert(0, PracticeWordItem(initialWord, '', 'Từ bài học'));
        startIndex = 0;
      }
    }

    state = state.copyWith(
      words: words,
      currentWordIndex: startIndex,
      isInitializing: true,
    );

    try {
      await ref.read(ttsServiceProvider).initialize();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await ref.read(speechRecognizerProvider).initialize();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    } catch (_) {}

    state = state.copyWith(isInitializing: false);
  }

  Future<bool> startRecording() async {
    _cleanupTimers();
    final voiceRecorder = ref.read(voiceRecorderProvider);
    final speechRecognizer = ref.read(speechRecognizerProvider);

    state = state.copyWith(
      isRecording: true,
      clearResult: true,
      currentAmplitude: 0.15,
      maxAmplitudeObserved: 0.15,
      recognizedWords: '',
      clearErrorMessage: true,
      permissionDenied: false,
    );

    _voiceDetected = false;
    _recordingStartedAt = DateTime.now();

    // 1. Kiểm tra và bật thu âm WAV qua VoiceRecorder
    bool started = false;
    try {
      started = await voiceRecorder.start();
    } catch (e) {
      debugPrint('VoiceRecorder.start exception: $e');
      started = false;
    }

    if (!started) {
      state = state.copyWith(
        isRecording: false,
        currentAmplitude: 0.0,
        permissionDenied: true,
        errorMessage: 'Ứng dụng bị từ chối quyền truy cập Micro. Vui lòng cấp quyền trong Cài đặt để thu âm.',
      );
      return false;
    }

    // Lắng nghe biên độ sóng âm
    _ampSub?.cancel();
    _ampSub = voiceRecorder.amplitude.listen((amp) {
      if (state.isRecording) {
        final maxAmp = amp > state.maxAmplitudeObserved ? amp : state.maxAmplitudeObserved;
        state = state.copyWith(
          currentAmplitude: amp,
          maxAmplitudeObserved: maxAmp,
        );
      }
    });

    // 2. Lắng nghe nhận dạng giọng nói zh-CN
    try {
      await speechRecognizer.listen(
        onResult: (text, isFinal) {
          if (text.isNotEmpty && state.isRecording) {
            state = state.copyWith(recognizedWords: text);
          }
          if (isFinal && state.isRecording) {
            _speechSilenceTimer?.cancel();
            _speechSilenceTimer = Timer(const Duration(milliseconds: 1800), () {
              if (state.isRecording) {
                stopAndAssess();
              }
            });
          }
        },
        onSoundLevel: (amp) {
          if (state.isRecording) {
            final maxAmp = amp > state.maxAmplitudeObserved ? amp : state.maxAmplitudeObserved;
            state = state.copyWith(
              currentAmplitude: amp,
              maxAmplitudeObserved: maxAmp,
            );
            if (amp >= 0.16) {
              _voiceDetected = true;
              _speechSilenceTimer?.cancel();
              _speechSilenceTimer = Timer(const Duration(milliseconds: 2500), () {
                if (state.isRecording) {
                  stopAndAssess();
                }
              });
            }
          }
        },
        onError: (err) {
          debugPrint('SpeechRecognizer note: $err');
        },
      );
    } catch (e) {
      debugPrint('SpeechRecognizer.listen exception: $e');
    }

    // Timeout an toàn 8 giây tự động dừng
    _silenceTimer = Timer(const Duration(seconds: 8), () {
      if (state.isRecording) {
        stopAndAssess();
      }
    });

    return true;
  }

  Future<void> stopAndAssess() async {
    _cleanupTimers();

    final voiceRecorder = ref.read(voiceRecorderProvider);
    final speechRecognizer = ref.read(speechRecognizerProvider);
    final pinyinService = ref.read(pinyinServiceProvider);
    final scorer = ref.read(pronunciationScorerProvider);
    final progressService = ref.read(progressServiceProvider);

    state = state.copyWith(
      isRecording: false,
      isAssessing: true,
      currentAmplitude: 0.0,
    );

    Recording? realRecording;
    try {
      realRecording = await voiceRecorder.stop();
    } catch (_) {}

    try {
      await speechRecognizer.stop();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } catch (_) {}

    final duration = _recordingStartedAt != null
        ? DateTime.now().difference(_recordingStartedAt!)
        : (realRecording?.duration ?? const Duration(seconds: 1));
    _recordingStartedAt = null;

    final recording = realRecording ?? Recording(path: null, duration: duration);

    if (state.recognizedWords.trim().isEmpty && _voiceDetected) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    final recognizedText = state.recognizedWords.trim();
    var recognizedPinyin = '';
    if (recognizedText.isNotEmpty) {
      if (RegExp(r'[a-zA-Z]').hasMatch(recognizedText) && !RegExp(r'[\u4e00-\u9fff]').hasMatch(recognizedText)) {
        recognizedPinyin = recognizedText;
      } else {
        try {
          recognizedPinyin = await pinyinService.toPinyin(recognizedText);
        } catch (_) {}
        if (recognizedPinyin.isEmpty && recognizedText == state.currentWord.hanzi) {
          recognizedPinyin = state.currentWord.pinyin;
        }
      }
    }

    final res = await scorer.assess(
      referenceHanzi: state.currentWord.hanzi,
      referencePinyin: state.currentWord.pinyin,
      recording: recording,
      recognizedPinyin: recognizedPinyin.isNotEmpty ? recognizedPinyin : null,
      recognizedText: recognizedText.isNotEmpty ? recognizedText : null,
    );

    // Xoá tệp âm thanh tạm sau khi đã gửi đi chấm
    if (recording.path != null) {
      try {
        final f = File(recording.path!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }

    // Ghi sự kiện học tập pronunciation_scored (#15 / #33)
    try {
      final toneScores = <String, int>{};
      for (final s in res.syllables) {
        if (s.expected.tone > 0) {
          toneScores[s.expected.tone.toString()] = s.score.toInt();
        }
      }
      final xpGained = res.overall >= 90 ? 5 : 2;
      final durSec = duration.inSeconds > 0 ? duration.inSeconds : 1;
      await progressService.record(
        LearningEvent(
          type: LearningEventType.pronunciationScored,
          score: res.overall,
          refId: state.currentWord.hanzi,
          xp: xpGained,
          durationSec: durSec,
          data: {
            'tones': toneScores,
            'source': res.source,
          },
        ),
      );
    } catch (e) {
      debugPrint('Failed to record pronunciation_scored event: $e');
    }

    state = state.copyWith(
      result: res,
      isAssessing: false,
    );
  }

  Future<void> testPinyinDirectly(String testPinyin) async {
    final scorer = ref.read(pronunciationScorerProvider);
    final progressService = ref.read(progressServiceProvider);

    state = state.copyWith(
      isAssessing: true,
      recognizedWords: testPinyin,
    );

    final res = await scorer.assess(
      referenceHanzi: state.currentWord.hanzi,
      referencePinyin: state.currentWord.pinyin,
      recording: const Recording(path: null, duration: Duration(milliseconds: 1200)),
      recognizedPinyin: testPinyin,
      recognizedText: testPinyin,
    );

    try {
      final toneScores = <String, int>{};
      for (final s in res.syllables) {
        if (s.expected.tone > 0) {
          toneScores[s.expected.tone.toString()] = s.score.toInt();
        }
      }
      await progressService.record(
        LearningEvent(
          type: LearningEventType.pronunciationScored,
          score: res.overall,
          refId: state.currentWord.hanzi,
          xp: res.overall >= 90 ? 5 : 2,
          durationSec: 1,
          data: {
            'tones': toneScores,
            'source': res.source,
          },
        ),
      );
    } catch (_) {}

    state = state.copyWith(
      result: res,
      isAssessing: false,
    );
  }

  Future<void> playTts({bool slow = false}) async {
    final now = DateTime.now();
    if (_lastTtsTap != null && now.difference(_lastTtsTap!).inMilliseconds < 450) {
      return;
    }
    _lastTtsTap = now;

    final tts = ref.read(ttsServiceProvider);
    state = state.copyWith(isPlayingTts: true);
    try {
      await tts.speak(state.currentWord.hanzi, slow: slow);
    } finally {
      state = state.copyWith(isPlayingTts: false);
    }
  }

  void nextWord() {
    _cleanupTimers();
    if (state.currentWordIndex < state.words.length - 1) {
      state = state.copyWith(
        currentWordIndex: state.currentWordIndex + 1,
        clearResult: true,
        recognizedWords: '',
        currentAmplitude: 0.0,
      );
    }
  }

  void prevWord() {
    _cleanupTimers();
    if (state.currentWordIndex > 0) {
      state = state.copyWith(
        currentWordIndex: state.currentWordIndex - 1,
        clearResult: true,
        recognizedWords: '',
        currentAmplitude: 0.0,
      );
    }
  }

  void dismissError() {
    state = state.copyWith(clearErrorMessage: true, permissionDenied: false);
  }

  void _cleanupTimers() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _speechSilenceTimer?.cancel();
    _speechSilenceTimer = null;
    _ampSub?.cancel();
    _ampSub = null;
  }
}

final pronunciationControllerProvider =
    NotifierProvider.autoDispose<PronunciationController, PronunciationState>(PronunciationController.new);
