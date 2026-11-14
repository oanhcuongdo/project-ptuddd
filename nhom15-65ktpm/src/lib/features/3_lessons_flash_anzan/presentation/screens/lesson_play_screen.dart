import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/attempt_log.dart';
import '../../../../shared/entities/soroban_question.dart';
import '../../../../shared/widgets/mascot_bubble.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/abacus_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/soroban_board_widget.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/presentation/widgets/voice_answer_mic_button.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/domain/question_generator.dart';

class LessonPlayScreen extends StatefulWidget {
  final int level;

  const LessonPlayScreen({super.key, required this.level});

  @override
  State<LessonPlayScreen> createState() => _LessonPlayScreenState();
}

class _LessonPlayScreenState extends State<LessonPlayScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();
  late AbacusController _abacusController;

  late SorobanQuestion _currentQuestion;
  int _questionIndex = 1;
  String _mascotSpeech = 'Bé hãy nhìn phép tính và gảy hạt bàn tính nhé!';
  DateTime _questionStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _abacusController = AbacusController(columnCount: 2);
    _loadNextQuestion();
  }

  @override
  void dispose() {
    _abacusController.dispose();
    super.dispose();
  }

  void _loadNextQuestion() {
    setState(() {
      _currentQuestion = QuestionGenerator.generate(widget.level);
      _abacusController.reset();
      _questionStartTime = DateTime.now();
      _mascotSpeech = 'Phép tính: ${_currentQuestion.formulaExpression} = ?';
    });
    _audioService.speak(
      'Bé ơi, hãy tính: ${_currentQuestion.formulaExpression}',
    );
  }

  Future<void> _checkAnswer(int answer, String answeredVia) async {
    final elapsed = DateTime.now().difference(_questionStartTime).inMilliseconds;
    final isCorrect = answer == _currentQuestion.expectedAnswer;

    final log = AttemptLog(
      questionId: _currentQuestion.id,
      userAnswer: answer,
      isCorrect: isCorrect,
      responseTimeMs: elapsed,
      answeredVia: answeredVia,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _storageService.saveAttemptLog(log);

    // Cập nhật streak nếu đúng
    if (isCorrect) {
      final profile = await _storageService.getChildProfile();
      await _storageService.saveChildProfile(
        profile.copyWith(streakCount: profile.streakCount + 1),
      );
      await _audioService.playSuccessFeedback();
    } else {
      await _audioService.playEncouragementFeedback();
    }

    // Đánh giá Adaptive Tutor
    final recentLogs = await _storageService.getRecentLogs();
    final decision = AdaptiveTutorEngine.evaluatePerformance(
      recentAttempts: recentLogs,
    );

    _showResultDialog(isCorrect: isCorrect, answer: answer, decision: decision);
  }

  void _showResultDialog({
    required bool isCorrect,
    required int answer,
    required AdaptiveDecision decision,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor:
              isCorrect ? const Color(0xFFF0FFF4) : const Color(0xFFFFF5F5),
          title: Text(
            isCorrect ? 'CHÍNH XÁC! ⭐' : 'BÉ CỐ LÊN NHÉ! 💖',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isCorrect ? AppColors.success : AppColors.error,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCorrect
                    ? 'Bé tính đúng rồi! Kết quả là $answer'
                    : 'Bé ra $answer, đáp án đúng là ${_currentQuestion.expectedAnswer}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  decision.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _questionIndex++);
                _loadNextQuestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCorrect ? AppColors.success : AppColors.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Câu tiếp theo ➡️',
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.level == 1
              ? 'Hạt Nhỏ Nhận Diện'
              : 'Công Thức Anh Bạn Nhỏ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  'Câu $_questionIndex',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mascot Bubble trên cùng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MascotBubbleWidget(
                speechText: _mascotSpeech,
                onMascotTap: () {
                  _audioService.speak(_mascotSpeech);
                },
              ),
            ),

            // Khung hiển thị phép tính to rõ
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentQuestion.formulaExpression,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // Bàn tính ảo Soroban
            Expanded(
              child: Center(
                child: SorobanBoardWidget(
                  controller: _abacusController,
                  height: 220,
                  showLiveValue: true,
                ),
              ),
            ),

            // Nút trả lời (Gửi kết quả bàn tính hoặc Bấm nói giọng nói)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _checkAnswer(
                        _abacusController.totalValue,
                        'abacus_touch',
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 28),
                    label: const Text('GỬI BÀN TÍNH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                  VoiceAnswerMicButton(
                    onAnswerDetected: (answer, raw) {
                      _checkAnswer(answer, 'voice');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
