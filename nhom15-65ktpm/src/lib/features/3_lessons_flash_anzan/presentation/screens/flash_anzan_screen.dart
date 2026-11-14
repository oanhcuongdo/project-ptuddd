import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/attempt_log.dart';
import '../../../../shared/entities/soroban_question.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/abacus_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/soroban_board_widget.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/presentation/widgets/voice_answer_mic_button.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/domain/question_generator.dart';

class FlashAnzanScreen extends StatefulWidget {
  final int initialSpeedMs;

  const FlashAnzanScreen({super.key, this.initialSpeedMs = 1200});

  @override
  State<FlashAnzanScreen> createState() => _FlashAnzanScreenState();
}

class _FlashAnzanScreenState extends State<FlashAnzanScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();
  late AbacusController _abacusController;

  late SorobanQuestion _currentQuestion;
  int _flashSpeedMs = 1200;

  bool _isFlashing = false;
  String _displayNumber = 'SẴN SÀNG?';
  Color _displayColor = AppColors.secondary;
  bool _waitingForAnswer = false;
  String _feedbackMessage = 'Bé nhìn kỹ các số xuất hiện nhé!';

  @override
  void initState() {
    super.initState();
    _flashSpeedMs = widget.initialSpeedMs;
    _abacusController = AbacusController(columnCount: 2);
    _nextQuestion();
  }

  @override
  void dispose() {
    _abacusController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion = QuestionGenerator.generate(3, flashSpeedMs: _flashSpeedMs);
      _abacusController.reset();
      _waitingForAnswer = false;
      _displayNumber = 'SẴN SÀNG?';
      _displayColor = AppColors.secondary;
      _feedbackMessage = 'Nhấn nút để bắt đầu tính nhẩm!';
    });
  }

  Future<void> _startFlashSequence() async {
    setState(() {
      _isFlashing = true;
      _waitingForAnswer = false;
      _displayNumber = '3';
      _displayColor = AppColors.accentOrange;
    });
    await _audioService.speak('Ba');
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _displayNumber = '2');
    await _audioService.speak('Hai');
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _displayNumber = '1');
    await _audioService.speak('Một');
    await Future.delayed(const Duration(milliseconds: 600));

    // Bắt đầu chớp số
    for (int i = 0; i < _currentQuestion.operands.length; i++) {
      if (!mounted) return;
      final val = _currentQuestion.operands[i];
      final valText = val >= 0 ? '+$val' : '$val';

      setState(() {
        _displayNumber = valText;
        _displayColor = val >= 0 ? AppColors.primary : AppColors.secondary;
      });

      _audioService.speak(val >= 0 ? 'Cộng $val' : 'Trừ ${val.abs()}');
      await Future.delayed(Duration(milliseconds: _flashSpeedMs));

      // Khoảng nghỉ trắng mắt giữa 2 số để kích thích não bộ hình dung
      if (!mounted) return;
      setState(() {
        _displayNumber = '';
      });
      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (!mounted) return;
    setState(() {
      _isFlashing = false;
      _waitingForAnswer = true;
      _displayNumber = '?';
      _displayColor = AppColors.accentYellow;
      _feedbackMessage = 'Bé gảy kết quả lên bàn tính hoặc đọc to nhé!';
    });
    await _audioService.speak('Bằng bao nhiêu bé ơi?');
  }

  Future<void> _checkAnswer(int answer, String answeredVia) async {
    if (!_waitingForAnswer) return;

    final isCorrect = answer == _currentQuestion.expectedAnswer;
    final log = AttemptLog(
      questionId: _currentQuestion.id,
      userAnswer: answer,
      isCorrect: isCorrect,
      responseTimeMs: 2000,
      answeredVia: answeredVia,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _storageService.saveAttemptLog(log);

    // AI Thích ứng: Đánh giá và tự động căn chỉnh tốc độ
    final recentLogs = await _storageService.getRecentLogs();
    final decision = AdaptiveTutorEngine.evaluatePerformance(
      recentAttempts: recentLogs,
      currentFlashSpeedMs: _flashSpeedMs,
    );

    setState(() {
      _flashSpeedMs = decision.recommendedSpeedMs;
      _waitingForAnswer = false;
    });

    if (isCorrect) {
      await _audioService.playSuccessFeedback();
      _showResultDialog(
        title: 'XUẤT SẮC! 🎉',
        message: 'Đúng rồi, đáp án là $answer!\n${decision.message}',
        isSuccess: true,
      );
    } else {
      await _audioService.playEncouragementFeedback();
      _showResultDialog(
        title: 'CỐ GẮNG NÀO! 💪',
        message:
            'Bé trả lời là $answer, đáp án chính xác là ${_currentQuestion.expectedAnswer}.\n${decision.message}',
        isSuccess: false,
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isSuccess ? const Color(0xFFF0FFF4) : const Color(0xFFFFF5F5),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextQuestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? AppColors.success : AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Câu tiếp theo ➡️', style: TextStyle(fontSize: 18)),
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
        title: const Text(
          '⚡ Flash Anzan - Tính Nhẩm Nhanh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed, size: 18, color: AppColors.accentOrange),
                const SizedBox(width: 4),
                Text(
                  '${(_flashSpeedMs / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Khung hiển thị số chớp nhoáng
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _displayColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: _displayColor.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _displayNumber,
                    style: const TextStyle(
                      fontSize: 82,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Lời hướng dẫn hoặc nút bắt đầu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _feedbackMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),

            if (!_isFlashing && !_waitingForAnswer)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: _startFlashSequence,
                  icon: const Icon(Icons.play_arrow, size: 32),
                  label: const Text('BẮT ĐẦU CHỚP SỐ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                ),
              ),

            // Bàn tính ảo để bé gảy kết quả
            Expanded(
              flex: 5,
              child: SorobanBoardWidget(
                controller: _abacusController,
                height: 200,
                showLiveValue: true,
              ),
            ),

            // Nút trả lời bằng bàn tính & Micro AI giọng nói
            if (_waitingForAnswer)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _checkAnswer(_abacusController.totalValue, 'abacus_touch');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: const Text('GỬI BÀN TÍNH ✅', style: TextStyle(fontSize: 16)),
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
