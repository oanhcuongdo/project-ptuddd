import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/core/services/audio_service.dart';
import 'package:soroban_kids_app/core/services/gamification_service.dart';
import 'package:soroban_kids_app/core/services/storage_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/widgets/badge_unlock_dialog.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/presentation/widgets/voice_answer_mic_button.dart';
import 'package:soroban_kids_app/features/question_generator/domain/question_generator.dart';
import 'package:soroban_kids_app/injection_container.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';

enum FlashState {
  idle,
  countdown,
  starting,
  flashing,
  pause,
  waitingAnswer,
  finished,
}

class _FlashStep {
  const _FlashStep(this.display, this.spoken, {this.isSubtraction = false});

  final String display;
  final String spoken;
  final bool isSubtraction;
}

class _FlashSessionResult {
  const _FlashSessionResult({
    required this.expression,
    required this.answer,
    required this.expectedAnswer,
    required this.isCorrect,
  });

  final String expression;
  final int answer;
  final int expectedAnswer;
  final bool isCorrect;
}

class FlashAnzanScreen extends StatefulWidget {
  const FlashAnzanScreen({super.key});

  @override
  State<FlashAnzanScreen> createState() => _FlashAnzanScreenState();
}

class _FlashAnzanScreenState extends State<FlashAnzanScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();
  final QuestionGenerator _questionGenerator = QuestionGenerator();

  FlashState _state = FlashState.idle;
  int _flashSpeedMs = 2500; // Tốc độ khởi đầu thân thiện với trẻ nhỏ.
  late final AdaptiveLearningEngine _adaptiveEngine;
  List<int> _numbers = [];
  List<_FlashStep> _flashSteps = [];
  int _currentIndex = 0;
  int _expectedAnswer = 0;
  int? _userAnswer;
  bool _isCorrect = false;
  int _pointsEarned = 0;
  int _streakMultiplier = 1;
  DateTime _questionStartTime = DateTime.now();
  Timer? _flashTimer;
  int _sessionToken = 0;
  int _countdownValue = 3;
  String _adaptiveNote = '';
  final List<_FlashSessionResult> _sessionResults = [];
  bool _isShowingSummary = false;
  bool _allowExit = false;

  @override
  void initState() {
    super.initState();
    _adaptiveEngine = AdaptiveLearningEngine(
      initialState: AdaptiveState(
        flashDurationMs: _flashSpeedMs,
      ),
    );
    _loadProfileSettings();
  }

  @override
  void dispose() {
    _sessionToken++;
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileSettings() async {
    final profile = await _storageService.getChildProfile();
    if (!mounted) return;
    final flashLevel = profile.flashAnzanLevel.clamp(1, 3).toInt();
    final minimumSpeed = flashLevel >= 3 ? 1000 : 2000;
    final flashSpeed = profile.flashSpeedMs.clamp(minimumSpeed, 2500).toInt();
    setState(() {
      _flashSpeedMs = flashSpeed;
      _adaptiveEngine.updateConfig(
        difficulty: flashLevel,
        flashDurationMs: flashSpeed,
      );
    });
  }

  void _startFlashSession() {
    _flashTimer?.cancel();
    final token = ++_sessionToken;
    final question = _questionGenerator.generateForLevel(
      QuestionLevel.flashAnzan,
      flashTermCount: 3,
      flashSpeedMs: _flashSpeedMs,
    );

    setState(() {
      _numbers = question.operands;
      _flashSteps = _buildFlashSteps(_numbers);
      _expectedAnswer = question.expectedAnswer;
      _currentIndex = 0;
      _userAnswer = null;
      _isCorrect = false;
      _pointsEarned = 0;
      _streakMultiplier = 1;
      _countdownValue = 3;
      _state = FlashState.countdown;
      _adaptiveNote = '';
    });

    _audioService.speak('Sẵn sàng chớp số nào!');
    unawaited(_playCountdownCue());
    _runCountdown(token);
  }

  Future<void> _playCountdownCue() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.selectionClick();
    } catch (_) {
      // The browser or device may not provide a system countdown cue.
    }
  }

  void _runCountdown(int token) {
    _flashTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || token != _sessionToken) return;
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
        unawaited(_playCountdownCue());
        _runCountdown(token);
      } else {
        setState(() => _state = FlashState.starting);
        _audioService.speak('Bắt đầu!');
        _flashTimer = Timer(const Duration(milliseconds: 700), () {
          if (!mounted || token != _sessionToken) return;
          _showFlashStep(0, token);
        });
      }
    });
  }

  List<_FlashStep> _buildFlashSteps(List<int> numbers) {
    if (numbers.isEmpty) return const [];
    final steps = <_FlashStep>[
      _FlashStep('${numbers.first}', '${numbers.first}'),
    ];
    for (final number in numbers.skip(1)) {
      final isSubtraction = number < 0;
      steps
        ..add(_FlashStep(
            isSubtraction ? '−' : '+', isSubtraction ? 'trừ' : 'cộng',
            isSubtraction: isSubtraction))
        ..add(_FlashStep('${number.abs()}', '${number.abs()}',
            isSubtraction: isSubtraction));
    }
    return steps;
  }

  void _showFlashStep(int index, int token) {
    if (!mounted || token != _sessionToken) return;
    setState(() {
      _currentIndex = index;
      _state = FlashState.flashing;
    });
    final step = _flashSteps[index];
    _audioService.speak(step.spoken);

    _flashTimer = Timer(Duration(milliseconds: _flashSpeedMs), () {
      if (!mounted || token != _sessionToken) return;
      setState(() => _state = FlashState.pause);
      _flashTimer = Timer(const Duration(milliseconds: 180), () {
        if (!mounted || token != _sessionToken) return;
        if (index + 1 < _flashSteps.length) {
          _showFlashStep(index + 1, token);
        } else {
          setState(() {
            _state = FlashState.waitingAnswer;
            _questionStartTime = DateTime.now();
          });
          _audioService.speak('Bằng:');
        }
      });
    });
  }

  Future<void> _submitAnswer(int answer,
      {String method = 'abacus_touch'}) async {
    if (_state != FlashState.waitingAnswer) return;

    final isCorrect = answer == _expectedAnswer;
    final responseTime =
        DateTime.now().difference(_questionStartTime).inMilliseconds;

    setState(() {
      _userAnswer = answer;
      _isCorrect = isCorrect;
      _state = FlashState.finished;
      _sessionResults.add(
        _FlashSessionResult(
          expression: _formatQuestionExpression(),
          answer: answer,
          expectedAnswer: _expectedAnswer,
          isCorrect: isCorrect,
        ),
      );
    });
    _sessionToken++;
    _flashTimer?.cancel();

    if (isCorrect) {
      _audioService.playSuccessFeedback();
    } else {
      _audioService.playEncouragementFeedback(
          'Đáp án chính xác là $_expectedAnswer bé nhé!');
    }

    // 1. Lưu bản ghi
    final log = AttemptLog(
      questionId: 'flash_${DateTime.now().millisecondsSinceEpoch}',
      userAnswer: answer,
      isCorrect: isCorrect,
      responseTimeMs: responseTime,
      answeredVia: method,
      timestamp: DateTime.now().toIso8601String(),
      difficultyLevel: 3,
      flashAnzanSpeedMs: _flashSpeedMs,
      questionText: _numbers.map((n) => n > 0 ? '+$n' : '$n').join(' '),
    );
    await _storageService.saveAttemptLog(log);

    // 2. Cập nhật Streak & Huy hiệu
    final profile = await _storageService.getChildProfile();
    final allLogs = await _storageService.getRecentLogs();
    final gamificationResult = GamificationService.processLessonCompletion(
      profile: profile,
      allLogs: allLogs,
    );
    await _storageService.saveChildProfile(gamificationResult.updatedProfile);

    if (gamificationResult.newlyUnlockedBadges.isNotEmpty && mounted) {
      BadgeUnlockDialog.show(context, gamificationResult.newlyUnlockedBadges);
    }

    // 3. Gia sư thích ứng điều chỉnh tốc độ Flash Anzan theo cửa sổ trượt
    final currentFlashLevel = _adaptiveEngine.state.currentDifficulty;
    final attempt = AttemptResult(
      isCorrect: _isCorrect,
      responseTimeMs: responseTime,
      mode: PracticeMode.flashAnzan,
      difficultyLevel: currentFlashLevel,
      flashDurationMs: _flashSpeedMs,
    );
    final decision = _adaptiveEngine.processAttempt(attempt);
    final flashLevel = decision.recommendedLevel.clamp(1, 3).toInt();
    var flashSpeed = _flashSpeedMs;

    if (decision.adaptationAction == AdaptationAction.levelUp) {
      if (flashLevel >= 3) {
        flashSpeed = max(
          _flashSpeedMs - AdaptiveLearningEngine.speedStepMs,
          1000,
        );
      } else {
        // Keep levels 1 and 2 slow; start speeding up only from level 3.
        flashSpeed = _flashSpeedMs.clamp(2000, 2500).toInt();
      }
    } else if (decision.adaptationAction == AdaptationAction.levelDown) {
      flashSpeed = min(
        _flashSpeedMs + AdaptiveLearningEngine.speedStepMs,
        2500,
      );
      if (flashLevel < 3) flashSpeed = max(flashSpeed, 2000);
    }

    _adaptiveEngine.updateConfig(
      difficulty: flashLevel,
      flashDurationMs: flashSpeed,
    );
    await _storageService.saveChildProfile(
      gamificationResult.updatedProfile.copyWith(
        flashAnzanLevel: flashLevel,
        flashSpeedMs: flashSpeed,
      ),
    );
    if (mounted) {
      setState(() {
        _pointsEarned = gamificationResult.pointsEarned;
        _streakMultiplier = gamificationResult.streakMultiplier;
      });
    }

    if (!mounted) return;
    setState(() {
      _flashSpeedMs = flashSpeed;
      _adaptiveNote = switch (decision.adaptationAction) {
        AdaptationAction.levelUp when flashLevel < 3 =>
          'Bé lên cấp $flashLevel rồi! Cùng luyện chắc tay ở nhịp chậm nhé!',
        AdaptationAction.levelUp when currentFlashLevel < 3 =>
          'Bé lên cấp 3! Thời gian chớp số sẽ rút ngắn dần khi bé làm tốt nhé!',
        AdaptationAction.levelUp =>
          'Bé làm tốt lắm! Nhịp chớp số giảm còn ${flashSpeed}ms nhé!',
        AdaptationAction.levelDown =>
          'Mình về cấp $flashLevel và đặt nhịp chớp ${flashSpeed}ms nhé!',
        AdaptationAction.maintain =>
          decision.message.isNotEmpty ? decision.message : decision.reason,
      };
    });
  }

  String _formatQuestionExpression() {
    if (_numbers.isEmpty) return '';
    final expression = StringBuffer('${_numbers.first}');
    for (final number in _numbers.skip(1)) {
      expression.write(number < 0 ? ' - ${number.abs()}' : ' + $number');
    }
    return expression.toString();
  }

  Future<void> _showSessionSummary() async {
    if (_isShowingSummary || _allowExit) return;
    _isShowingSummary = true;

    final wasInProgress = _state == FlashState.countdown ||
        _state == FlashState.starting ||
        _state == FlashState.flashing ||
        _state == FlashState.pause ||
        _state == FlashState.waitingAnswer;
    _sessionToken++;
    _flashTimer?.cancel();
    await _audioService.stopFeedback();
    if (!mounted) {
      _isShowingSummary = false;
      return;
    }

    final results = List<_FlashSessionResult>.unmodifiable(_sessionResults);
    final correct = results.where((result) => result.isCorrect).length;
    final wrong = results.length - correct;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final resultListHeight =
            min(300.0, max(150.0, screenSize.height * 0.38));
        return AlertDialog(
          title: const Text('Kết quả lượt chơi'),
          content: SizedBox(
            width: min(420.0, screenSize.width * 0.82),
            height: results.isEmpty ? 72 : resultListHeight,
            child: results.isEmpty
                ? const Align(
                    alignment: Alignment.topLeft,
                    child: Text('Bé chưa trả lời câu nào trong lượt này.'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đúng: $correct    Sai: $wrong'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final result = results[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${result.expression} = ${result.expectedAnswer}',
                              ),
                              subtitle: Text(
                                result.isCorrect
                                    ? 'Đúng'
                                    : 'Sai: ${result.answer}',
                                style: TextStyle(
                                  color: result.isCorrect
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CHƠI TIẾP'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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

    _isShowingSummary = false;
    if (!mounted) return;
    if (shouldExit == true) {
      setState(() => _allowExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } else if (wasInProgress) {
      setState(() => _state = FlashState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_showSessionSummary());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: const Text('⚡ Flash Anzan Tính Nhẩm'),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            tooltip: 'Về trang chủ',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _showSessionSummary,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_state == FlashState.countdown ||
                        _state == FlashState.starting) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                AppColors.accentOrange.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _state == FlashState.countdown
                                  ? Icons.timer_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: AppColors.accentOrange,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _state == FlashState.countdown
                                  ? 'SẴN SÀNG: $_countdownValue'
                                  : 'BẮT ĐẦU!',
                              style: const TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Thẻ tốc độ hiện tại
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cấp ${_adaptiveEngine.state.currentDifficulty} • ${_flashSpeedMs}ms / nhịp',
                        style: const TextStyle(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Màn hình hiển thị số chớp
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: _state == FlashState.flashing
                              ? AppColors.accentPurple
                              : Colors.grey.shade300,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.accentPurple.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _buildCenterDisplay(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_state == FlashState.waitingAnswer) ...[
                      const Text(
                        'Bé hãy đọc to đáp án vào Micro hoặc chọn số:',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      VoiceAnswerMicButton(
                        onAnswerDetected: (answer, raw) =>
                            _submitAnswer(answer, method: 'voice'),
                        onHintRequested: (speech) {
                          _audioService.speak(
                              'Gợi ý: Phép tính là ${_numbers.join(", ")}');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildQuickAnswerButtons(),
                    ],

                    if (_state == FlashState.finished) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? const Color(0xFFE8F7EE)
                              : const Color(0xFFFFF1E8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isCorrect
                                ? AppColors.success
                                : AppColors.error,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isCorrect
                                  ? '🎉 HOÀN TOÀN CHÍNH XÁC! 🎉'
                                  : 'BÉ CHƯA ĐÚNG RỒI!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _isCorrect
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đáp án đúng là: $_expectedAnswer (Bé chọn: $_userAnswer)',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            if (_isCorrect) ...[
                              const SizedBox(height: 4),
                              Text(
                                '+$_pointsEarned điểm (x$_streakMultiplier theo chuỗi học)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                            if (_adaptiveNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '💡 Thích ứng AI: $_adaptiveNote',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textLight),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _startFlashSession,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('BÀI TIẾP THEO',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ],

                    if (_state == FlashState.idle)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _startFlashSession,
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: const Text('BẮT ĐẦU CHỚP SỐ ⚡',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterDisplay() {
    if (_state == FlashState.idle) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚡', style: TextStyle(fontSize: 64)),
          SizedBox(height: 8),
          Text(
            'Nhấn nút để bắt đầu chớp số',
            style: TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    if (_state == FlashState.countdown) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_rounded,
              size: 56, color: AppColors.accentPurple),
          SizedBox(height: 12),
          Text(
            'Bé chuẩn bị quan sát nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
            ),
          ),
        ],
      );
    }

    if (_state == FlashState.starting) {
      return const Text(
        'BẮT ĐẦU!',
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: AppColors.accentOrange,
        ),
      );
    }

    if (_state == FlashState.flashing) {
      final step = _flashSteps[_currentIndex];
      return Text(
        step.display,
        style: TextStyle(
          fontSize: 84,
          fontWeight: FontWeight.w900,
          color: step.isSubtraction ? AppColors.error : AppColors.primary,
        ),
      );
    }

    if (_state == FlashState.pause) return const SizedBox.shrink();

    if (_state == FlashState.waitingAnswer) {
      return const Text(
        '= ?',
        style: TextStyle(
            fontSize: 92,
            fontWeight: FontWeight.w900,
            color: AppColors.accentOrange),
      );
    }

    return Text(
      '$_expectedAnswer',
      style: TextStyle(
        fontSize: 84,
        fontWeight: FontWeight.w900,
        color: _isCorrect ? AppColors.success : AppColors.error,
      ),
    );
  }

  Widget _buildQuickAnswerButtons() {
    final opts = <int>{_expectedAnswer};
    final random = Random();
    for (final offset in [-3, -2, -1, 1, 2, 3]) {
      final candidate = _expectedAnswer + offset;
      if (candidate >= 0 && candidate <= 99) opts.add(candidate);
    }
    while (opts.length < 4) {
      opts.add(random.nextInt(100));
    }
    final list = opts.toList()..shuffle();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columnCount = constraints.maxWidth >= 500
            ? 7
            : constraints.maxWidth >= 360
                ? 4
                : 3;
        final buttonWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: list.map((n) {
            return SizedBox(
              width: buttonWidth,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 2,
                  minimumSize: Size(buttonWidth, 50),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _submitAnswer(n),
                child: Text(
                  '$n',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
