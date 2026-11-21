import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai_generator/models/generated_set.dart';
import '../../ai_generator/models/quiz_question_item.dart';
import '../models/quiz_attempt.dart';
import '../services/practice_service.dart';

class QuizAnalyticsScreen extends ConsumerStatefulWidget {
  final GeneratedSet generatedSet;
  final String quizId;
  final List<QuizQuestionItem>? initialQuestions;
  final QuizAnalyticsSummary? initialSummary;

  const QuizAnalyticsScreen({
    super.key,
    required this.generatedSet,
    required this.quizId,
    this.initialQuestions,
    this.initialSummary,
  });

  @override
  ConsumerState<QuizAnalyticsScreen> createState() =>
      _QuizAnalyticsScreenState();
}

class _QuizAnalyticsScreenState extends ConsumerState<QuizAnalyticsScreen> {
  QuizAnalyticsSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialSummary != null) {
      _summary = widget.initialSummary;
      _isLoading = false;
    } else {
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final service = ref.read(practiceServiceProvider);
    final questions = widget.initialQuestions ??
        await service.fetchQuizQuestions(widget.quizId);
    final summary = await service.fetchQuizAnalytics(widget.quizId, questions);

    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thống kê kết quả Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final summary = _summary!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê: ${widget.generatedSet.title}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview statistics (PRA-03)
          Text(
            'Tổng quan kết quả phòng (PRA-03)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              _MetricCard(
                label: 'Lượt nộp',
                value: '${summary.totalAttempts}',
                icon: Icons.assignment_turned_in_outlined,
                color: Colors.blue,
              ),
              _MetricCard(
                label: 'Điểm trung bình',
                value: '${summary.averageScore}',
                icon: Icons.analytics_outlined,
                color: Colors.orange,
              ),
              _MetricCard(
                label: 'Điểm cao nhất',
                value: '${summary.highestScore}',
                icon: Icons.emoji_events_outlined,
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Per-question accuracy rate (PRA-03)
          Text(
            'Tỷ lệ trả lời đúng theo từng câu hỏi',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Giúp Mentor nhận diện kiến thức còn yếu để tập trung giải đáp:',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          if (summary.questionStats.isEmpty)
            const Text('Chưa có dữ liệu thống kê câu hỏi.')
          else
            ...List.generate(summary.questionStats.length, (idx) {
              final stat = summary.questionStats[idx];
              final percent = (stat.correctRate * 100).round();
              final isWeak = stat.totalCount > 0 && percent < 50;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isWeak ? Colors.red.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Câu ${idx + 1}: ${stat.questionText}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isWeak)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CẦN GIẢI ĐÁP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: stat.correctRate,
                              backgroundColor: Colors.grey.shade200,
                              color: isWeak ? Colors.red : (percent >= 80 ? Colors.green : Colors.orange),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$percent% (${stat.correctCount}/${stat.totalCount})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isWeak ? Colors.red : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // Recent submissions list
          if (summary.recentAttempts.isNotEmpty) ...[
            Text(
              'Lịch sử các lượt nộp bài gần đây',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...summary.recentAttempts.map((attempt) {
              return Card(
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: attempt.score >= 7 ? Colors.green.shade100 : Colors.orange.shade100,
                    child: Text(
                      attempt.score.toStringAsFixed(0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: attempt.score >= 7 ? Colors.green.shade900 : Colors.orange.shade900,
                      ),
                    ),
                  ),
                  title: Text(attempt.userFullName ?? 'Học viên'),
                  subtitle: Text(
                    'Đúng ${attempt.correctCount}/${attempt.totalCount} câu • Điểm: ${attempt.score}',
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
