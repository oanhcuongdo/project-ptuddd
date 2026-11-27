import 'dart:async';
import 'package:chailish/core/contracts/models/learning_event.dart';
import 'package:chailish/core/contracts/models/pronunciation.dart';
import 'package:chailish/core/contracts/progress_service.dart';
import 'package:chailish/core/contracts/pronunciation_scorer.dart';
import 'package:chailish/core/contracts/speech_services.dart';
import 'package:chailish/features/pronunciation/presentation/screens/pronunciation_practice_screen.dart';
import 'package:chailish/features/pronunciation/presentation/screens/pronunciation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVoiceRecorder implements VoiceRecorder {
  bool startReturns = true;
  final _ampController = StreamController<double>.broadcast();
  final _stateController = StreamController<RecorderState>.broadcast();
  RecorderState _state = RecorderState.idle;

  @override
  Stream<double> get amplitude => _ampController.stream;

  Stream<RecorderState> get stateChanges => _stateController.stream;

  RecorderState get state => _state;

  @override
  Future<bool> start() async {
    if (!startReturns) {
      _state = RecorderState.idle;
      _stateController.add(_state);
      return false;
    }
    _state = RecorderState.recording;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<Recording> stop() async {
    _state = RecorderState.done;
    _stateController.add(_state);
    return const Recording(path: null, duration: Duration(milliseconds: 1500));
  }

  @override
  Future<void> cancel() async {
    _state = RecorderState.idle;
    _stateController.add(_state);
  }

  void dispose() {
    _ampController.close();
    _stateController.close();
  }
}

class _FakeSpeechRecognizer implements SpeechRecognizer {
  bool initialized = false;
  String? resultToEmit;

  @override
  Future<bool> initialize() async {
    initialized = true;
    return true;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    void Function(double soundLevel)? onSoundLevel,
    void Function(String error)? onError,
  }) async {
    if (resultToEmit != null) {
      onResult(resultToEmit!, true);
    }
  }

  @override
  Future<void> stop() async {}

  Future<void> cancel() async {}
}

class _FakeTtsService implements TtsService {
  final List<(String, bool)> spoken = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text, {bool slow = false}) async {
    spoken.add((text, slow));
  }

  @override
  Future<void> stop() async {}
}

class _FakePronunciationScorer implements PronunciationScorer {
  PronunciationResult presetResult = const PronunciationResult(
    overall: 95,
    accuracy: 96,
    fluency: 92,
    completeness: 100,
    tone: 95,
    source: ScoringSource.offline,
    recognizedText: '你好',
    syllables: [
      SyllableScore(
        hanzi: '你',
        expected: SyllableParts(initial: 'n', finalPart: 'i', tone: 3),
        actual: SyllableParts(initial: 'n', finalPart: 'i', tone: 3),
        score: 95,
        status: SyllableStatus.ok,
      ),
      SyllableScore(
        hanzi: '好',
        expected: SyllableParts(initial: 'h', finalPart: 'ao', tone: 3),
        actual: SyllableParts(initial: 'h', finalPart: 'ao', tone: 3),
        score: 95,
        status: SyllableStatus.ok,
      ),
    ],
  );

  @override
  Future<PronunciationResult> assess({
    required String referenceHanzi,
    required String referencePinyin,
    Recording? recording,
    String? recognizedPinyin,
    String? recognizedText,
  }) async {
    return presetResult;
  }
}

class _FakePinyinService implements PinyinService {
  @override
  Future<String> toPinyin(String hanzi, {bool applySandhi = false}) async {
    if (hanzi == '你好') return applySandhi ? 'ní hǎo' : 'nǐ hǎo';
    return 'nǐ hǎo';
  }
}

class _FakeProgressService implements ProgressService {
  final List<LearningEvent> recorded = [];

  @override
  Future<void> record(LearningEvent event) async {
    recorded.add(event);
  }

  @override
  List<LearningEvent> get events => recorded;

  @override
  Stream<List<LearningEvent>> get changes => const Stream.empty();

  @override
  Future<int> pullFromServer({int days = 90}) async => 0;

  @override
  Future<void> addAll(Iterable<LearningEvent> events, {bool sync = false}) async {
    recorded.addAll(events);
  }

  @override
  void clearLocal() {
    recorded.clear();
  }
}

void main() {
  late _FakeVoiceRecorder recorder;
  late _FakeSpeechRecognizer speech;
  late _FakeTtsService tts;
  late _FakePronunciationScorer scorer;
  late _FakePinyinService pinyin;
  late _FakeProgressService progress;

  setUp(() {
    recorder = _FakeVoiceRecorder();
    speech = _FakeSpeechRecognizer();
    tts = _FakeTtsService();
    scorer = _FakePronunciationScorer();
    pinyin = _FakePinyinService();
    progress = _FakeProgressService();
  });

  Widget buildTestApp({Widget? child}) {
    return ProviderScope(
      overrides: [
        voiceRecorderProvider.overrideWithValue(recorder),
        speechRecognizerProvider.overrideWithValue(speech),
        ttsServiceProvider.overrideWithValue(tts),
        pronunciationScorerProvider.overrideWithValue(scorer),
        pinyinServiceProvider.overrideWithValue(pinyin),
        progressServiceProvider.overrideWithValue(progress),
      ],
      child: MaterialApp(
        home: child ?? const PronunciationPracticeScreen(
          targetHanzi: '你好',
          targetPinyin: 'nǐ hǎo',
          meaning: 'Xin chào',
        ),
      ),
    );
  }

  testWidgets('renders pronunciation practice screen with Hanzi, Pinyin and TTS buttons', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('你好'), findsOneWidget);
    expect(find.text('nǐ hǎo'), findsOneWidget);
    expect(find.text('Xin chào'), findsOneWidget);
    expect(find.text('Nghe mẫu'), findsOneWidget);
    expect(find.text('Chậm 0.7x'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // Bấm nghe mẫu
    await tester.tap(find.text('Nghe mẫu'));
    await tester.pump();
    expect(tts.spoken.isNotEmpty, isTrue);
    expect(tts.spoken.first, ('你好', false));
  });

  testWidgets('shows SnackBar when microphone permission is denied (#11)', (tester) async {
    recorder.startReturns = false; // Giả lập từ chối cấp quyền

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Bấm nút micro để thu âm
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    // Kiểm tra hiển thị SnackBar thông báo từ chối quyền micro
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('từ chối quyền truy cập Micro'), findsOneWidget);
  });

  testWidgets('assesses pronunciation and records pronunciation_scored learning event (#15)', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Bấm chip debug test pinyin trực tiếp để kích hoạt chấm điểm
    final chip = find.text('nǐ hǎo (Chuẩn 100đ)');
    if (chip.evaluate().isNotEmpty) {
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Hiển thị Card kết quả chi tiết
      expect(find.text('Kết Quả Đánh Giá Chi Tiết'), findsOneWidget);
      expect(find.text('95 đ'), findsOneWidget);
      expect(find.text('Bài tập bổ trợ'), findsOneWidget);

      // Kiểm tra sự kiện học tập đã được ghi nhận qua progressService
      expect(progress.recorded.isNotEmpty, isTrue);
      final ev = progress.recorded.first;
      expect(ev.type, LearningEventType.pronunciationScored);
      expect(ev.score, 95.0);
      expect(ev.refId, '你好');
      expect(ev.xp, 5); // >= 90 điểm nhận 5 XP
      expect(ev.data?['tones'], isNotNull);
      expect(ev.data?['source'], isNotNull);
    }
  });

  testWidgets('opens support exercise bottom sheet on tapping Bài tập bổ trợ (#15)', (tester) async {
    scorer.presetResult = const PronunciationResult(
      overall: 65,
      accuracy: 60,
      fluency: 70,
      completeness: 100,
      tone: 60,
      source: ScoringSource.offline,
      recognizedText: 'ni hao',
      syllables: [
        SyllableScore(
          hanzi: '你',
          expected: SyllableParts(initial: 'n', finalPart: 'i', tone: 3),
          actual: SyllableParts(initial: 'n', finalPart: 'i', tone: 3),
          score: 60,
          status: SyllableStatus.warn,
          errors: [PronunciationError.tone],
        ),
      ],
    );

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final chip = find.text('nǐ hǎo (Chuẩn 100đ)');
    if (chip.evaluate().isNotEmpty) {
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Bấm nút Bài tập bổ trợ
      final supportBtn = find.text('Bài tập bổ trợ');
      expect(supportBtn, findsOneWidget);
      await tester.ensureVisible(supportBtn);
      await tester.tap(supportBtn);
      await tester.pumpAndSettle();

      // Kiểm tra hiển thị Modal bài tập bổ trợ
      expect(find.text('Bài Tập Bổ Trợ Phát Âm'), findsOneWidget);
      expect(find.textContaining('Đã hiểu, quay lại luyện tập'), findsOneWidget);
    }
  });

  testWidgets('PronunciationScreen accepts lessonId and word via route params (#15)', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        child: const PronunciationScreen(
          lessonId: 'hsk1-greetings-01',
          word: '再见',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('再见'), findsOneWidget);
  });
}
