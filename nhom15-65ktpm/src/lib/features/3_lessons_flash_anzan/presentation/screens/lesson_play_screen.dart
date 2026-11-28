
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/core/services/audio_service.dart';
import 'package:soroban_kids_app/core/services/gamification_service.dart';
import 'package:soroban_kids_app/core/services/storage_service.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/finger_math_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/widgets/badge_unlock_dialog.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/presentation/widgets/voice_answer_mic_button.dart';
import 'package:soroban_kids_app/features/question_generator/domain/question_generator.dart';
import 'package:soroban_kids_app/injection_container.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';
import 'package:soroban_kids_app/shared/entities/soroban_question.dart';

/// Arithmetic practice for basic and friend-rule levels with AI Voice & Adaptive Learning.
class LessonPlayScreen extends StatefulWidget {
  const LessonPlayScreen({super.key, this.level = 1});

  final int level;

  @override
  State<LessonPlayScreen> createState() => _LessonPlayScreenState();
}

class _LessonPlayScreenState extends State<LessonPlayScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storageService = sl<StorageService>();
  final AudioService _audioService = sl<AudioService>();
  final QuestionGenerator _generator = QuestionGenerator();

  late final AnimationController _confettiController;
  late final FingerMathController _fingerController;
  late final AdaptiveLearningEngine _adaptiveEngine;
  late final AnimationController _confettiController;
  late SorobanQuestion _question;

  DateTime _questionStartTime = DateTime.now();

  bool get _isLevel2 => widget.level == 2;

  bool _showHint = false;
  bool _hasCheckedAnswer = false;
  bool _answeredCorrectly = false;

  int _questionNumber = 1;
  int _pointsEarned = 0;
  int _streakMultiplier = 1;

  String _adaptiveFeedbackMessage = '';

  final List<_QuestionSessionResult> _sessionResults = [];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _adaptiveEngine = AdaptiveLearningEngine(
      initialState: AdaptiveState(
        currentDifficulty: widget.level,
        isFingerGuideEnabled: false,
      ),
    );

    _fingerController = FingerMathController(showLeftHand: _isLevel2);

    _loadQuestion(isFirstQuestion: true);
  }

  @override
  void dispose() {
    unawaited(_audioService.stopFeedback());
    _confettiController.dispose();
    _fingerController.dispose();
    super.dispose();
  }

  void _loadQuestion({bool isFirstQuestion = false}) {
    _question = _generator.generateForLevel(
      _isLevel2 ? QuestionLevel.friendRules : QuestionLevel.basic,
    );

    _fingerController.setValue(_question.operands.first);

    _showHint = _adaptiveEngine.state.isFingerGuideEnabled;

    _confettiController.reset();

    _hasCheckedAnswer = false;
    _answeredCorrectly = false;
    _pointsEarned = 0;
    _streakMultiplier = 1;
    _adaptiveFeedbackMessage = '';

    _questionStartTime = DateTime.now();

    if (!isFirstQuestion) _questionNumber++;
  }

  Future<void> _checkAnswer({
    int? voiceAnswer,
    String rawSpeech = '',
  }) async {
    if (_hasCheckedAnswer && _answeredCorrectly) return;

    final ans = voiceAnswer ?? _fingerController.totalValue;
    final isCorrect = ans == _question.expectedAnswer;

    final responseTime =
        DateTime.now().difference(_questionStartTime).inMilliseconds;

    setState(() {
      _hasCheckedAnswer = true;
      _answeredCorrectly = isCorrect;
      _recordAnswer(ans, isCorrect);
    });

    if (isCorrect) {
      final soundStarted = await _audioService.playCorrectAnswerSound();

      if (soundStarted && mounted) {
        _confettiController.forward(from: 0);
      }
    } else {
      unawaited(_audioService.playIncorrectAnswerSound());
    }

    // 1. Lưu bản ghi AttemptLog
    final log = AttemptLog(
      questionId: _question.id,
      userAnswer: ans,
      isCorrect: isCorrect,
      responseTimeMs: responseTime,
      answeredVia: voiceAnswer != null ? 'voice' : 'abacus_touch',
      timestamp: DateTime.now().toIso8601String(),
      difficultyLevel: widget.level,
      questionText: '${_question.formulaExpression} = ?',
    );

    await _storageService.saveAttemptLog(log);

    // 2. Cập nhật chuỗi Streak & Kiểm tra mở khóa Huy hiệu
    final profile = await _storageService.getChildProfile();
    final allLogs = await _storageService.getRecentLogs();

    final gamificationResult =
        GamificationService.processLessonCompletion(
      profile: profile,
      allLogs: allLogs,
    );

    await _storageService.saveChildProfile(
      gamificationResult.updatedProfile,
    );

    if (mounted) {
      setState(() {
        _pointsEarned = gamificationResult.pointsEarned;
        _streakMultiplier = gamificationResult.streakMultiplier;
      });
    }

    if (gamificationResult.newlyUnlockedBadges.isNotEmpty && mounted) {
      BadgeUnlockDialog.show(
        context,
        gamificationResult.newlyUnlockedBadges,
      );
    }

    // 3. Gia sư thích ứng đánh giá và hỗ trợ theo cửa sổ trượt
    final attempt = AttemptResult(
      isCorrect: isCorrect,
      responseTimeMs: responseTime,
      mode: PracticeMode.fingerMath,
      difficultyLevel: widget.level,
    );

    final decision = _adaptiveEngine.processAttempt(attempt);

    if (mounted) {
      setState(() {
        _adaptiveFeedbackMessage = decision.message;

        if (decision.fingerGuideEnabled) {
          _showHint = true;
        }
      });
    }
  }

  void _recordAnswer(int answer, bool isCorrect) {
    final existing = _sessionResults.where(
      (result) => result.number == _questionNumber,
    );

    if (existing.isNotEmpty) {
      final result = existing.first;
      result.answer = answer;
      result.isCorrect = isCorrect;
      result.skipped = false;
      return;
    }

    _sessionResults.add(
      _QuestionSessionResult(
        number: _questionNumber,
        expression: _question.formulaExpression,
        answer: answer,
        expectedAnswer: _question.expectedAnswer,
        isCorrect: isCorrect,
      ),
    );
  }

  void _skipQuestion() {
    unawaited(_audioService.stopFeedback());

    final existing = _sessionResults.where(
      (result) => result.number == _questionNumber,
    );

    if (existing.isEmpty) {
      _sessionResults.add(
        _QuestionSessionResult(
          number: _questionNumber,
          expression: _question.formulaExpression,
          expectedAnswer: _question.expectedAnswer,
          skipped: true,
        ),
      );
    } else {
      // Keep a wrong answer as wrong when the child skips afterward.
      existing.first.skipped = false;
    }

    setState(_loadQuestion);
  }

  Future<void> _showSessionSummary() async {
    await _audioService.stopFeedback();

    if (!mounted) return;

    final results =
        List<_QuestionSessionResult>.unmodifiable(_sessionResults);

    final correct =
        results.where((result) => result.isCorrect == true).length;

    final wrong = results
        .where((result) => result.isCorrect == false && !result.skipped)
        .length;

    final skipped = results.where((result) => result.skipped).length;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);

        final resultListHeight = math.min(
          300.0,
          math.max(150.0, screenSize.height * 0.38),
        );

        return AlertDialog(
          title: const Text('Kết quả lượt chơi'),
          content: SizedBox(
            width: math.min(420.0, screenSize.width * 0.82),
            height: results.isEmpty ? 112 : resultListHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đúng: $correct    Sai: $wrong    Bỏ qua: $skipped'),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const Text('Bé chưa hoàn thành câu nào trong lượt này.')
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = results[index];

                        final status = result.skipped
                            ? 'Đã bỏ qua'
                            : result.isCorrect == true
                                ? 'Đúng'
                                : 'Sai: ${result.answer} (đáp án ${result.expectedAnswer})';

                        final color = result.isCorrect == true
                            ? AppColors.success
                            : result.skipped
                                ? AppColors.textLight
                                : AppColors.error;

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Câu ${result.number}: ${result.expression} = ${result.expectedAnswer}',
                          ),
                          subtitle: Text(
                            status,
                            style: TextStyle(color: color),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CHƠI TIẾP'),
            ),
            FilledButton(
              onPressed: () async {
                await _audioService.stopFeedback();

                if (!dialogContext.mounted || !mounted) return;

                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('KẾT THÚC'),
            ),
          ],
        );
      },
    );
  }

  void _tryAgain() {
    unawaited(_audioService.stopFeedback());

    setState(() {
      _fingerController.setValue(_question.operands.first);
      _hasCheckedAnswer = false;
      _questionStartTime = DateTime.now();
    });
  }

  void _nextQuestion() {
    unawaited(_audioService.stopFeedback());
    setState(_loadQuestion);
  }

  @override
  Widget build(BuildContext context) {
    final firstOperand = _question.operands[0];
    final secondOperand = _question.operands[1];

    final isAddition =
        _question.operation == ArithmeticOperation.addition;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_showSessionSummary());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isLevel2
                ? 'Cấp độ 2 · Anh bạn nhỏ & Anh bạn lớn'
                : 'Cấp độ 1 · Bé cùng tính nhé!',
          ),
          backgroundColor: AppColors.cardBg,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Kết thúc và xem kết quả',
            onPressed: _showSessionSummary,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.error,
            ),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final handBoardHeight =
                      (constraints.maxHeight * 0.35)
                          .clamp(160.0, 240.0)
                          .toDouble();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Câu số $_questionNumber',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _isLevel2 ? 'Khó hơn' : 'Cơ bản',
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: Text(
                                'Bé hãy gảy ngón tay hoặc bấm Micro để nói đáp án nhé!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.secondary,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${_question.formulaExpression} = ?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (_isLevel2)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: _buildHintSection(secondOperand),
                              ),
                            if (!_isLevel2)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  isAddition
                                      ? 'Bắt đầu từ $firstOperand rồi xòe thêm $secondOperand nhé.'
                                      : 'Bắt đầu từ $firstOperand rồi gập bớt $secondOperand nhé.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: FingerMathBoardWidget(
                                controller: _fingerController,
                                height: handBoardHeight,
                                showLiveValue: true,
                                isGuideEnabled: _showHint ||
                                    _adaptiveEngine.state.isFingerGuideEnabled,
                              ),
                            ),
                            // Nút Micro AI nhận diện giọng nói tiếng Việt (Mục 7.7)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              child: VoiceAnswerMicButton(
                                onAnswerDetected: (number, raw) {
                                  _fingerController.setValue(number);
                                  _checkAnswer(
                                    voiceAnswer: number,
                                    rawSpeech: raw,
                                  );
                                },
                                onHintRequested: (speech) {
                                  setState(() => _showHint = true);
                                  _audioService.speak(
                                    'Đừng lo bé nhé! ${_question.formulaExpression}. Bé hãy quan sát ngón tay nè!',
                                  );
                                },
                                onStatusChanged: (status) {
                                  // Cập nhật trạng thái nếu cần
                                },
                              ),
                            ),
                            if (_adaptiveFeedbackMessage.isNotEmpty &&
                                !_answeredCorrectly)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                child: Text(
                                  _adaptiveFeedbackMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            if (_hasCheckedAnswer)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  8,
                                ),
                                child: _buildAnswerFeedback(
                                  firstOperand: firstOperand,
                                  secondOperand: secondOperand,
                                  isAddition: isAddition,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                20,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _answeredCorrectly
                                          ? _nextQuestion
                                          : !_hasCheckedAnswer
                                              ? () => _checkAnswer()
                                              : _tryAgain,
                                      icon: Icon(
                                        _answeredCorrectly
                                            ? Icons.arrow_forward_rounded
                                            : !_hasCheckedAnswer
                                                ? Icons.check_rounded
                                                : Icons.refresh_rounded,
                                      ),
                                      label: Text(
                                        _answeredCorrectly
                                            ? 'CÂU TIẾP THEO'
                                            : !_hasCheckedAnswer
                                                ? 'KIỂM TRA BÀN TAY'
                                                : 'THỬ LẠI',
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            AppColors.secondary,
                                        foregroundColor:
                                            AppColors.onSecondary,
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 17,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!_answeredCorrectly) ...[
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      onPressed: _skipQuestion,
                                      icon: const Icon(
                                        Icons.skip_next_rounded,
                                      ),
                                      label: const Text('BỎ QUA'),
                                      style: OutlinedButton.styleFrom(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _confettiController.value,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintSection(int secondOperand) {
    final isSmallFriend = _question.type == QuestionType.smallFriend;
    final base = isSmallFriend ? 5 : 10;
    final complement = base - secondOperand;

    final isAddition =
        _question.operation == ArithmeticOperation.addition;

    final rule = isAddition
        ? '+$secondOperand = +$base - $complement'
        : '-$secondOperand = -$base + $complement';

    final instruction = isAddition
        ? 'Bé hãy thêm $base trước, rồi bớt lại $complement nhé!'
        : 'Bé hãy bớt $base trước, rồi thêm lại $complement nhé!';

    return Column(
      children: [
        FilledButton.icon(
          onPressed: () => setState(() => _showHint = !_showHint),
          icon: Icon(
            _showHint
                ? Icons.lightbulb
                : Icons.lightbulb_outline,
            size: 23,
          ),
          label: Text(_showHint ? 'ẨN GỢI Ý' : 'GỢI Ý'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor:
                AppColors.accentOrange.withValues(alpha: 0.4),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        if (_showHint)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(
              top: 10,
              bottom: 8,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3B0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFC107),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8EFF5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '🐼',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Panda hướng dẫn bé',
                      style: TextStyle(
                        color: Color(0xFF8A4B08),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8A4B08),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rule,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8A4B08),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hãy cùng thử lại nhé!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8A4B08),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerFeedback({
    required int firstOperand,
    required int secondOperand,
    required bool isAddition,
  }) {
    final backgroundColor = _answeredCorrectly
        ? const Color(0xFFE8F7EE)
        : const Color(0xFFFFF1E8);

    final accentColor =
        _answeredCorrectly ? AppColors.success : AppColors.error;

    final title = _answeredCorrectly
        ? 'CHÍNH XÁC!'
        : 'CHƯA ĐÚNG, BÉ THỬ LẠI NHÉ!';

    final message = _answeredCorrectly
        ? 'Bé đã tìm được đáp án ${_question.expectedAnswer}. Giỏi quá! '
            '+$_pointsEarned điểm (x$_streakMultiplier theo chuỗi học).'
        : 'Bàn tay đang chỉ số ${_fingerController.totalValue}. '
            '${isAddition ? 'Bắt đầu từ $firstOperand rồi xòe thêm $secondOperand ngón.' : 'Bắt đầu từ $firstOperand rồi gập bớt $secondOperand ngón.'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _answeredCorrectly
                ? Icons.celebration_rounded
                : Icons.lightbulb_outline_rounded,
            color: accentColor,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionSessionResult {
  _QuestionSessionResult({
    required this.number,
    required this.expression,
    required this.expectedAnswer,
    this.answer,
    this.isCorrect,
    this.skipped = false,
  });

  final int number;
  final String expression;
  final int expectedAnswer;

  int? answer;
  bool? isCorrect;
  bool skipped;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final random = math.Random(1506);

    const colors = [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFD166),
      Color(0xFF9D4EDD),
      Color(0xFFFF9F1C),
    ];

    final opacity =
        ((1 - progress) * 1.6).clamp(0.0, 1.0).toDouble();

    for (var i = 0; i < 56; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = -20 - random.nextDouble() * 130;
      final speed = 0.65 + random.nextDouble() * 0.65;
      final phase = random.nextDouble() * math.pi * 2;

      final y =
          startY + progress * (size.height + 170) * speed;

      if (y < -20 || y > size.height + 24) continue;

      final x = startX + math.sin(progress * 8 + phase) * 20;

      final width = 5 + random.nextDouble() * 5;
      final height = 8 + random.nextDouble() * 7;

      final paint = Paint()
        ..color = colors[i % colors.length]
            .withValues(alpha: opacity);

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(progress * 8 + phase)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: height,
            ),
            const Radius.circular(2),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
