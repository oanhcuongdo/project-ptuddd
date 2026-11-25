import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../ai_generator/models/generated_set.dart';
import '../../ai_generator/models/quiz_question_item.dart';
import '../models/quiz_attempt.dart';
import '../services/practice_service.dart';

class QuizTakingScreen extends ConsumerStatefulWidget {
  final GeneratedSet generatedSet;
  final String quizId;
  final String userId;
  final List<QuizQuestionItem>? initialQuestions;
  final int timeLimitMinutes;

  const QuizTakingScreen({
    super.key,
    required this.generatedSet,
    required this.quizId,
    required this.userId,
    this.initialQuestions,
    this.timeLimitMinutes = 15,
  });

  @override
  ConsumerState<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen> {
  List<QuizQuestionItem> _questions = [];
  final Map<String, int> _selectedAnswers = {}; // questionId -> selectedIndex
  bool _isLoading = true;
  bool _isSubmitting = false;
  QuizAttempt? _submittedResult;

  // Countdown timer
  Timer? _countdownTimer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeLimitMinutes * 60;
    if (widget.initialQuestions != null) {
      _questions = List.from(widget.initialQuestions!);
      _isLoading = false;
      _startTimer();
    } else {
      _loadQuestions();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _handleTimeUp();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _handleTimeUp() {
    if (_submittedResult != null || _isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hết giờ làm bài! Hệ thống đang tự động nộp bài của bạn.'),
        backgroundColor: Colors.orange,
      ),
    );
    _submitQuiz(force: true);
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final service = ref.read(practiceServiceProvider);
    final questions = await service.fetchQuizQuestions(widget.quizId);
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  Future<void> _submitQuiz({bool force = false}) async {
    if (!force) {
      final unanswered = _questions.length - _selectedAnswers.length;
      if (unanswered > 0) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Còn câu chưa làm'),
            content: Text('Bạn còn $unanswered câu chưa chọn đáp án. Bạn có chắc chắn muốn nộp bài không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Tiếp tục làm'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Nộp luôn'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    _countdownTimer?.cancel();
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(practiceServiceProvider);
      final result = await service.submitQuizAttempt(
        quizId: widget.quizId,
        userId: widget.userId,
        questions: _questions,
        selectedAnswers: _selectedAnswers,
      );

      if (mounted) {
        setState(() {
          _submittedResult = result;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nộp bài: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.generatedSet.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_submittedResult != null) {
      return _buildResultView();
    }

    final isTimeLow = _remainingSeconds <= 120; // 2 minutes left

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.generatedSet.title),
        actions: [
          // Countdown Timer pill
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isTimeLow ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTimeLow ? Colors.red.shade300 : Colors.blue.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isTimeLow ? Colors.red : Colors.blue.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isTimeLow ? Colors.red.shade800 : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_selectedAnswers.length}/${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _questions.isEmpty
          ? const Center(child: Text('Chưa có câu hỏi nào trong bài trắc nghiệm.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: ResponsiveContainer(
                maxWidth: 780,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...List.generate(_questions.length, (index) {
                      final q = _questions[index];
                      final selectedOption = _selectedAnswers[q.id];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Câu ${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      q.questionText,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              ...List.generate(q.options.length, (optIdx) {
                                final isSelected = selectedOption == optIdx;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => setState(() => _selectedAnswers[q.id] = optIdx),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primaryContainer.withAlpha(128)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey.shade300,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          size: 20,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${String.fromCharCode(65 + optIdx)}. ${q.options[optIdx]}',
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Nộp bài kiểm tra'),
            onPressed: (_isSubmitting || _questions.isEmpty) ? null : () => _submitQuiz(),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _submittedResult!;
    final score = result.score;
    final isGood = score >= 7.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả làm bài'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: ResponsiveContainer(
          maxWidth: 780,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score summary card
              Card(
                color: isGood ? Colors.green.shade50 : Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isGood ? Colors.green.shade300 : Colors.orange.shade300,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        isGood ? 'Hoàn thành xuất sắc!' : 'Cần cố gắng thêm!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isGood ? Colors.green.shade900 : Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${score.toStringAsFixed(1)} / 10',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isGood ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đúng ${result.correctCount}/${result.totalCount} câu hỏi',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chi tiết đáp án & giải thích (PRA-02):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Detailed questions review
              ...List.generate(_questions.length, (idx) {
                final q = _questions[idx];
                final selected = _selectedAnswers[q.id];
                final isCorrect = selected == q.correctIndex;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Câu ${idx + 1}: ${isCorrect ? 'Đúng' : 'Sai'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...List.generate(q.options.length, (optIdx) {
                          final isAnswer = optIdx == q.correctIndex;
                          final isUserChosen = optIdx == selected;

                          Color? bg;
                          if (isAnswer) bg = Colors.green.shade50;
                          if (isUserChosen && !isAnswer) bg = Colors.red.shade50;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(6),
                              border: isAnswer
                                  ? Border.all(color: Colors.green)
                                  : (isUserChosen ? Border.all(color: Colors.red) : null),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${String.fromCharCode(65 + optIdx)}. ',
                                  style: TextStyle(fontWeight: isAnswer ? FontWeight.bold : FontWeight.normal),
                                ),
                                Expanded(child: Text(q.options[optIdx])),
                                if (isAnswer)
                                  const Icon(Icons.check, color: Colors.green, size: 16),
                                if (isUserChosen && !isAnswer)
                                  const Icon(Icons.close, color: Colors.red, size: 16),
                              ],
                            ),
                          );
                        }),
                        if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Giải thích: ${q.explanation}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng & Quay lại phòng học'),
          ),
        ),
      ),
    );
  }
}
