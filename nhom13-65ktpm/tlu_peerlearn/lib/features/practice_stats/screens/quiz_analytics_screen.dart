import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/responsive_container.dart';
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
  Map<String, String> _userNames = {};
  int _totalRoomMentees = 0;
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

    final Map<String, String> names = {};
    final userIds = summary.recentAttempts.map((a) => a.userId).toSet().toList();
    if (userIds.isNotEmpty) {
      for (final table in ['ck_profiles', 'profiles']) {
        try {
          final rows = await Supabase.instance.client
              .from(table)
              .select('id, full_name')
              .inFilter('id', userIds);
          for (final r in rows as List<dynamic>) {
            final id = r['id'] as String?;
            final name = r['full_name'] as String?;
            if (id != null && name != null && name.isNotEmpty) {
              names[id] = name;
            }
          }
          if (names.isNotEmpty) break;
        } catch (_) {}
      }
    }

    int totalMentees = 0;
    try {
      final members = await Supabase.instance.client
          .from('ck_room_members')
          .select('user_id')
          .eq('room_id', widget.generatedSet.roomId)
          .neq('role', 'mentor');
      totalMentees = (members as List<dynamic>).length;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _summary = summary;
        _userNames = names;
        _totalRoomMentees = totalMentees;
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
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overview statistics (PRA-03)
              Text(
                'Tổng quan kết quả phòng',
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
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
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

              // Score distribution chart & latest attempt per student
              if (summary.recentAttempts.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    // Keep only the latest attempt per student
                    final Map<String, QuizAttempt> latestByUser = {};
                    for (final a in summary.recentAttempts) {
                      latestByUser.putIfAbsent(a.userId, () => a);
                    }
                    final latestAttempts = latestByUser.values.toList();
                    final doneCount = latestAttempts.length;
                    final menteeLabel = _totalRoomMentees > 0
                        ? '$doneCount/$_totalRoomMentees mentee đã làm'
                        : '$doneCount học viên đã làm';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Phân bố mức điểm',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                menteeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ScoreDistributionCard(attempts: latestAttempts),
                        const SizedBox(height: 24),
                        Text(
                          'Điểm sau cùng của từng học viên ($doneCount)',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: latestAttempts.map((a) {
                              final color = a.score >= 8.0
                                  ? Colors.green
                                  : (a.score >= 5.0
                                      ? Colors.orange
                                      : Colors.red);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      color.withValues(alpha: 0.15),
                                  child: Icon(Icons.person_outline,
                                      color: color),
                                ),
                                title: Text(
                                  _userNames[a.userId] ?? 'Học viên',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Nộp lúc: ${a.submittedAt.hour.toString().padLeft(2, '0')}:${a.submittedAt.minute.toString().padLeft(2, '0')} ${a.submittedAt.day}/${a.submittedAt.month}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${a.score.toStringAsFixed(1)}/10',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Per-question accuracy rate
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
                      padding: const EdgeInsets.all(14),
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
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isWeak)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          const SizedBox(height: 10),
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
                              const SizedBox(width: 12),
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
        ),
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
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
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


class _ScoreDistributionCard extends StatelessWidget {
  final List<QuizAttempt> attempts;

  const _ScoreDistributionCard({required this.attempts});

  @override
  Widget build(BuildContext context) {
    final total = attempts.length;
    final excellent = attempts.where((a) => a.score >= 8.0).length;
    final good = attempts.where((a) => a.score >= 6.5 && a.score < 8.0).length;
    final average =
        attempts.where((a) => a.score >= 5.0 && a.score < 6.5).length;
    final weak = attempts.where((a) => a.score < 5.0).length;

    final buckets = [
      ('Giỏi (8.0 - 10)', excellent, Colors.green),
      ('Khá (6.5 - 7.9)', good, Colors.blue),
      ('Trung bình (5.0 - 6.4)', average, Colors.orange),
      ('Cần cố gắng (< 5.0)', weak, Colors.red),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: buckets.map((b) {
            final label = b.$1;
            final count = b.$2;
            final color = b.$3;
            final ratio = total == 0 ? 0.0 : count / total;
            final pct = (ratio * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$count người ($pct%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
