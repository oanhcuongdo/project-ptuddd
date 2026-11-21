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

class _LessonPlayScreenState extends State<LessonPlayScreen> {
  final StorageService _storageService = sl<StorageService>();
  final AudioService _audioService = sl<AudioService>();
  final QuestionGenerator _generator = QuestionGenerator();
  late final FingerMathController _fingerController;
  late SorobanQuestion _question;
  DateTime _questionStartTime = DateTime.now();

  bool get _isLevel2 => widget.level == 2;

  bool _showHint = false;
  bool _hasCheckedAnswer = false;
  bool _answeredCorrectly = false;
  int _questionNumber = 1;
  String _adaptiveFeedbackMessage = '';

  @override
  void initState() {
    super.initState();
    _fingerController = FingerMathController(showLeftHand: _isLevel2);
    _loadQuestion(isFirstQuestion: true);
  }

  @override
  void dispose() {
    _fingerController.dispose();
    super.dispose();
  }

  void _loadQuestion({bool isFirstQuestion = false}) {
    _question = _generator.generateForLevel(
      _isLevel2 ? QuestionLevel.friendRules : QuestionLevel.basic,
    );
    _fingerController.setValue(_question.operands.first);
    _showHint = false;
    _hasCheckedAnswer = false;
    _answeredCorrectly = false;
    _adaptiveFeedbackMessage = '';
    _questionStartTime = DateTime.now();
    if (!isFirstQuestion) _questionNumber++;
  }

  Future<void> _checkAnswer({int? voiceAnswer, String rawSpeech = ''}) async {
    if (_hasCheckedAnswer && _answeredCorrectly) return;

    final ans = voiceAnswer ?? _fingerController.totalValue;
    final isCorrect = ans == _question.expectedAnswer;
    final responseTime = DateTime.now().difference(_questionStartTime).inMilliseconds;

    setState(() {
      _hasCheckedAnswer = true;
      _answeredCorrectly = isCorrect;
    });

    if (isCorrect) {
      _audioService.playSuccessFeedback();
    } else {
      _audioService.playEncouragementFeedback();
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
    final gamificationResult = GamificationService.processLessonCompletion(
      profile: profile,
      allLogs: allLogs,
    );
    await _storageService.saveChildProfile(gamificationResult.updatedProfile);

    if (gamificationResult.newlyUnlockedBadges.isNotEmpty && mounted) {
      BadgeUnlockDialog.show(context, gamificationResult.newlyUnlockedBadges);
    }

    // 3. Gia sư thích ứng đánh giá và hỗ trợ
    final decision = AdaptiveTutorEngine.evaluatePerformance(
      recentAttempts: allLogs,
      currentLevel: widget.level,
    );

    if (mounted) {
      setState(() {
        _adaptiveFeedbackMessage = decision.message;
        if (decision.fingerGuideEnabled) {
          _showHint = true;
        }
      });
    }
  }

  void _tryAgain() {
    setState(() {
      _fingerController.setValue(_question.operands.first);
      _hasCheckedAnswer = false;
      _questionStartTime = DateTime.now();
    });
  }

  void _nextQuestion() {
    setState(_loadQuestion);
  }

  @override
  Widget build(BuildContext context) {
    final firstOperand = _question.operands[0];
    final secondOperand = _question.operands[1];
    final isAddition = _question.operation == ArithmeticOperation.addition;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLevel2
              ? 'Cấp độ 2 · Anh bạn nhỏ & Anh bạn lớn'
              : 'Cấp độ 1 · Bé cùng tính nhé!',
        ),
        backgroundColor: AppColors.cardBg,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final handBoardHeight =
                (constraints.maxHeight * 0.35).clamp(160.0, 240.0).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                            horizontal: 20, vertical: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: AppColors.secondary, width: 2),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildHintSection(secondOperand),
                        ),
                      if (!_isLevel2)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            isAddition
                                ? 'Bắt đầu từ $firstOperand rồi xòe thêm $secondOperand nhé.'
                                : 'Bắt đầu từ $firstOperand rồi gập bớt $secondOperand nhé.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FingerMathBoardWidget(
                          controller: _fingerController,
                          height: handBoardHeight,
                          showLiveValue: true,
                        ),
                      ),

                      // Nút Micro AI nhận diện giọng nói tiếng Việt (Mục 7.7)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: VoiceAnswerMicButton(
                          onAnswerDetected: (number, raw) {
                            _fingerController.setValue(number);
                            _checkAnswer(voiceAnswer: number, rawSpeech: raw);
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

                      if (_adaptiveFeedbackMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: _buildAnswerFeedback(
                            firstOperand: firstOperand,
                            secondOperand: secondOperand,
                            isAddition: isAddition,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
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
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                            ),
                          ),
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
    );
  }

  Widget _buildHintSection(int secondOperand) {
    final isSmallFriend = _question.type == QuestionType.smallFriend;
    final base = isSmallFriend ? 5 : 10;
    final complement = base - secondOperand;
    final isAddition = _question.operation == ArithmeticOperation.addition;
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
            _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
            size: 23,
          ),
          label: Text(_showHint ? 'ẨN GỢI Ý' : 'GỢI Ý'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: AppColors.accentOrange.withValues(alpha: 0.4),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        if (_showHint)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2DC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF09838),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF9E4517),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rule,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF9E4517),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hãy quan sát bàn tay để thực hiện theo hướng dẫn nhé!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9E4517),
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
    final backgroundColor =
        _answeredCorrectly ? const Color(0xFFE8F7EE) : const Color(0xFFFFF1E8);
    final accentColor =
        _answeredCorrectly ? AppColors.success : AppColors.error;
    final title =
        _answeredCorrectly ? 'CHÍNH XÁC!' : 'CHƯA ĐÚNG, BÉ THỬ LẠI NHÉ!';
    final message = _answeredCorrectly
        ? 'Bé đã tìm được đáp án ${_question.expectedAnswer}. Giỏi quá!'
        : 'Bàn tay đang chỉ số ${_fingerController.totalValue}. '
            '${isAddition ? 'Bắt đầu từ $firstOperand rồi xòe thêm $secondOperand ngón.' : 'Bắt đầu từ $firstOperand rồi gập bớt $secondOperand ngón.'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor, width: 2),
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
