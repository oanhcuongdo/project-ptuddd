import 'package:flutter/material.dart';
import '../models/flashcard_item.dart';
import '../models/generated_set.dart';
import '../models/quiz_question_item.dart';

class PublishedSetDetailScreen extends StatefulWidget {
  final GeneratedSet set;
  final List<FlashcardItem>? flashcards;
  final List<QuizQuestionItem>? questions;

  const PublishedSetDetailScreen({
    super.key,
    required this.set,
    this.flashcards,
    this.questions,
  });

  @override
  State<PublishedSetDetailScreen> createState() => _PublishedSetDetailScreenState();
}

class _PublishedSetDetailScreenState extends State<PublishedSetDetailScreen> {
  final Set<int> _flippedCards = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuiz = widget.set.isQuiz;
    final count = isQuiz ? (widget.questions?.length ?? 0) : (widget.flashcards?.length ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.set.title),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'ĐÃ PHÁT HÀNH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Metadata header card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isQuiz ? Icons.quiz_outlined : Icons.style_outlined,
                          color: isQuiz ? Colors.blue.shade700 : Colors.purple.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isQuiz ? 'Bài trắc nghiệm ($count câu)' : 'Bộ thẻ ghi nhớ ($count thẻ)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chủ đề: ${widget.set.topic ?? "Tổng hợp"}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        Text('Độ khó: ${widget.set.difficulty.toUpperCase()}', style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phiên bản: v${widget.set.version}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items list
            if (isQuiz) _buildQuizQuestions() else _buildFlashcards(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizQuestions() {
    final list = widget.questions ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('Không có câu hỏi nào.'));
    }

    return Column(
      children: List.generate(list.length, (index) {
        final q = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Câu ${index + 1}: ${q.questionText}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...List.generate(q.options.length, (optIdx) {
                  final isCorrect = optIdx == q.correctIndex;
                  final cleanOption = q.options[optIdx].replaceFirst(RegExp(r'^[A-Da-d]\.\s*'), '');
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade50 : null,
                      borderRadius: BorderRadius.circular(6),
                      border: isCorrect ? Border.all(color: Colors.green) : null,
                    ),
                    child: Row(
                      children: [
                        Text('${String.fromCharCode(65 + optIdx)}. ', style: TextStyle(fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal)),
                        Expanded(child: Text(cleanOption)),
                        if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ],
                    ),
                  );
                }),
                if (q.explanation != null) ...[
                  const SizedBox(height: 8),
                  Text('Giải thích: ${q.explanation}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFlashcards() {
    final list = widget.flashcards ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('Không có thẻ ghi nhớ nào.'));
    }

    return Column(
      children: List.generate(list.length, (index) {
        final card = list[index];
        final isFlipped = _flippedCards.contains(index);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                if (isFlipped) {
                  _flippedCards.remove(index);
                } else {
                  _flippedCards.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thẻ #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.flip, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            isFlipped ? 'Mặt sau (Đáp án)' : 'Mặt trước (Nhấn để lật)',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    isFlipped ? card.backText : card.frontText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isFlipped ? FontWeight.normal : FontWeight.w600,
                      color: isFlipped ? Colors.black87 : Colors.blue.shade900,
                    ),
                  ),
                  if (isFlipped && card.explanation != null) ...[
                    const SizedBox(height: 8),
                    Text('Giải thích: ${card.explanation}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
