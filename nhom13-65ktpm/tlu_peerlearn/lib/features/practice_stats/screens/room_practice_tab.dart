import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai_generator/models/generated_set.dart';
import '../models/quiz_attempt.dart';
import '../services/practice_service.dart';
import 'flashcard_study_screen.dart';
import 'quiz_analytics_screen.dart';
import 'quiz_taking_screen.dart';

class RoomPracticeTab extends ConsumerStatefulWidget {
  final String roomId;
  final String? currentUserId;
  final bool isMentor;

  const RoomPracticeTab({
    super.key,
    required this.roomId,
    this.currentUserId,
    this.isMentor = false,
  });

  @override
  ConsumerState<RoomPracticeTab> createState() => _RoomPracticeTabState();
}

class _RoomPracticeTabState extends ConsumerState<RoomPracticeTab> {
  PersonalPracticeSummary? _personalSummary;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final uid = widget.currentUserId;
    if (uid == null) return;

    setState(() => _isLoadingSummary = true);
    final service = ref.read(practiceServiceProvider);
    final summary = await service.fetchPersonalSummary(uid);
    if (mounted) {
      setState(() {
        _personalSummary = summary;
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _openQuiz(GeneratedSet set) async {
    final service = ref.read(practiceServiceProvider);
    final quizData = await service.fetchQuizBySetId(set.id);
    final quizId = quizData != null ? quizData['id'] as String : set.id;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizTakingScreen(
          generatedSet: set,
          quizId: quizId,
          userId: widget.currentUserId ?? 'current_user',
        ),
      ),
    );
    _loadSummary();
  }

  Future<void> _openAnalytics(GeneratedSet set) async {
    final service = ref.read(practiceServiceProvider);
    final quizData = await service.fetchQuizBySetId(set.id);
    final quizId = quizData != null ? quizData['id'] as String : set.id;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizAnalyticsScreen(
          generatedSet: set,
          quizId: quizId,
        ),
      ),
    );
  }

  Future<void> _openFlashcards(GeneratedSet set) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardStudyScreen(
          generatedSet: set,
          userId: widget.currentUserId ?? 'current_user',
        ),
      ),
    );
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(roomPublishedSetsProvider(widget.roomId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomPublishedSetsProvider(widget.roomId));
          await _loadSummary();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal practice summary card (PRA-04)
            if (_personalSummary != null && !_isLoadingSummary)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Tiến độ tự học cá nhân (PRA-04)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(
                            label: 'Quiz đã làm',
                            value: '${_personalSummary!.totalQuizzesTaken}',
                          ),
                          _SummaryItem(
                            label: 'Điểm TB Quiz',
                            value: '${_personalSummary!.averageScore}',
                          ),
                          _SummaryItem(
                            label: 'Flashcard thuộc',
                            value: '${_personalSummary!.rememberedFlashcards}/${_personalSummary!.totalFlashcardsStudied}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Text(
              'Bài ôn tập đã phát hành trong phòng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            setsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text('Lỗi tải bài ôn tập: $err')),
              data: (sets) {
                if (sets.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.school_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có bài ôn tập nào được phát hành.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mentor sẽ tạo và duyệt bài Flashcard/Quiz từ kho tài liệu.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final flashcardSets = sets.where((s) => s.isFlashcard).toList();
                final quizSets = sets.where((s) => s.isQuiz).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (flashcardSets.isNotEmpty) ...[
                      const Text(
                        'Bộ Thẻ Flashcard',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      ...flashcardSets.map((s) => _buildSetCard(s, isQuiz: false)),
                      const SizedBox(height: 16),
                    ],
                    if (quizSets.isNotEmpty) ...[
                      const Text(
                        'Bài Trắc Nghiệm (Quiz)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      ...quizSets.map((s) => _buildSetCard(s, isQuiz: true)),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetCard(GeneratedSet set, {required bool isQuiz}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isQuiz ? Colors.deepPurple.shade100 : Colors.blue.shade100,
          child: Icon(
            isQuiz ? Icons.quiz_outlined : Icons.style_outlined,
            color: isQuiz ? Colors.deepPurple.shade900 : Colors.blue.shade900,
          ),
        ),
        title: Text(set.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Độ khó: ${set.difficulty.toUpperCase()} ${set.topic != null ? '• Chủ đề: ${set.topic}' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isQuiz)
              IconButton(
                tooltip: 'Thống kê kết quả phòng',
                icon: const Icon(Icons.bar_chart, color: Colors.orange),
                onPressed: () => _openAnalytics(set),
              ),
            FilledButton.tonal(
              onPressed: () {
                if (isQuiz) {
                  _openQuiz(set);
                } else {
                  _openFlashcards(set);
                }
              },
              child: Text(isQuiz ? 'Làm bài' : 'Học thẻ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }
}
