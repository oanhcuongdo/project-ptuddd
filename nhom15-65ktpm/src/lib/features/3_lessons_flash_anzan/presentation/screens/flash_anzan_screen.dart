import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/core/services/audio_service.dart';
import 'package:soroban_kids_app/core/services/gamification_service.dart';
import 'package:soroban_kids_app/core/services/storage_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/widgets/badge_unlock_dialog.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/presentation/widgets/voice_answer_mic_button.dart';
import 'package:soroban_kids_app/injection_container.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';

enum FlashState { idle, ready, flashing, waitingAnswer, finished }

class FlashAnzanScreen extends StatefulWidget {
  const FlashAnzanScreen({super.key});

  @override
  State<FlashAnzanScreen> createState() => _FlashAnzanScreenState();
}

class _FlashAnzanScreenState extends State<FlashAnzanScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();

  FlashState _state = FlashState.idle;
  int _flashSpeedMs = 1200; // Tốc độ chớp số thích ứng
  List<int> _numbers = [];
  int _currentIndex = 0;
  int _expectedAnswer = 0;
  int? _userAnswer;
  bool _isCorrect = false;
  DateTime _questionStartTime = DateTime.now();
  Timer? _flashTimer;
  String _adaptiveNote = '';

  @override
  void initState() {
    super.initState();
    _loadProfileSettings();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileSettings() async {
    final profile = await _storageService.getChildProfile();
    setState(() {
      _flashSpeedMs = profile.flashSpeedMs;
    });
  }

  void _startFlashSession() {
    final random = Random();
    // Sinh chuỗi 3 số đơn giản 1-9 với tổng không âm
    final count = 3;
    final nums = <int>[];
    int sum = 0;

    for (int i = 0; i < count; i++) {
      if (i == 0) {
        final n = random.nextInt(5) + 1;
        nums.add(n);
        sum = n;
      } else {
        final add = random.nextBool();
        if (add) {
          final n = random.nextInt(4) + 1;
          nums.add(n);
          sum += n;
        } else {
          final n = min(random.nextInt(3) + 1, sum);
          nums.add(-n);
          sum -= n;
        }
      }
    }

    setState(() {
      _numbers = nums;
      _expectedAnswer = sum;
      _currentIndex = 0;
      _userAnswer = null;
      _isCorrect = false;
      _state = FlashState.flashing;
      _adaptiveNote = '';
    });

    _audioService.speak('Sẵn sàng chớp số nào!');

    _flashTimer = Timer.periodic(Duration(milliseconds: _flashSpeedMs), (timer) {
      if (_currentIndex < _numbers.length - 1) {
        setState(() {
          _currentIndex++;
        });
        final currentNum = _numbers[_currentIndex];
        final spoken = currentNum > 0 ? 'cộng $currentNum' : 'trừ ${currentNum.abs()}';
        _audioService.speak(spoken);
      } else {
        timer.cancel();
        setState(() {
          _state = FlashState.waitingAnswer;
          _questionStartTime = DateTime.now();
        });
        _audioService.speak('Bằng mấy bé ơi? Hãy đọc to hoặc chọn đáp án!');
      }
    });
  }

  Future<void> _submitAnswer(int answer, {String method = 'abacus_touch'}) async {
    if (_state != FlashState.waitingAnswer) return;

    final isCorrect = answer == _expectedAnswer;
    final responseTime = DateTime.now().difference(_questionStartTime).inMilliseconds;

    setState(() {
      _userAnswer = answer;
      _isCorrect = isCorrect;
      _state = FlashState.finished;
    });

    if (isCorrect) {
      _audioService.playSuccessFeedback();
    } else {
      _audioService.playEncouragementFeedback('Đáp án chính xác là $_expectedAnswer bé nhé!');
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

    // 3. Gia sư thích ứng điều chỉnh tốc độ Flash Anzan
    final decision = AdaptiveTutorEngine.evaluatePerformance(
      recentAttempts: allLogs,
      currentFlashSpeedMs: _flashSpeedMs,
      currentLevel: 3,
    );

    setState(() {
      _flashSpeedMs = decision.recommendedSpeedMs;
      _adaptiveNote = decision.reason;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('⚡ Flash Anzan Tính Nhẩm'),
        backgroundColor: Colors.white,
        elevation: 0.5,
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
                  // Thẻ tốc độ hiện tại
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tốc độ chớp số AI: ${_flashSpeedMs}ms / số',
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
                          color: AppColors.accentPurple.withValues(alpha: 0.15),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    VoiceAnswerMicButton(
                      onAnswerDetected: (answer, raw) => _submitAnswer(answer, method: 'voice'),
                      onHintRequested: (speech) {
                        _audioService.speak('Gợi ý: Phép tính là ${_numbers.join(", ")}');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildQuickAnswerButtons(),
                  ],

                  if (_state == FlashState.finished) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isCorrect ? const Color(0xFFE8F7EE) : const Color(0xFFFFF1E8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isCorrect ? AppColors.success : AppColors.error,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isCorrect ? '🎉 HOÀN TOÀN CHÍNH XÁC! 🎉' : 'BÉ CHƯA ĐÚNG RỒI!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _isCorrect ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đáp án đúng là: $_expectedAnswer (Bé chọn: $_userAnswer)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (_adaptiveNote.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '💡 Thích ứng AI: $_adaptiveNote',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: _startFlashSession,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('BÀI TIẾP THEO', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ],

                  if (_state == FlashState.idle)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _startFlashSession,
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text('BẮT ĐẦU CHỚP SỐ ⚡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                ],
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
            style: TextStyle(fontSize: 16, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    if (_state == FlashState.flashing) {
      final currentNum = _numbers[_currentIndex];
      final sign = currentNum > 0 ? (_currentIndex > 0 ? '+' : '') : '';
      return Text(
        '$sign$currentNum',
        style: TextStyle(
          fontSize: 84,
          fontWeight: FontWeight.w900,
          color: currentNum > 0 ? AppColors.primary : AppColors.error,
        ),
      );
    }

    if (_state == FlashState.waitingAnswer) {
      return const Text(
        '?',
        style: TextStyle(fontSize: 92, fontWeight: FontWeight.w900, color: AppColors.accentOrange),
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
    while (opts.length < 4) {
      final fake = (_expectedAnswer + random.nextInt(7) - 3).clamp(0, 18);
      opts.add(fake);
    }
    final list = opts.toList()..shuffle();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: list.map((n) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 2,
            minimumSize: const Size(60, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _submitAnswer(n),
          child: Text('$n', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        );
      }).toList(),
    );
  }
}
