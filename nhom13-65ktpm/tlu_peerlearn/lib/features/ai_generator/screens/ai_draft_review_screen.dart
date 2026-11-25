import 'package:flutter/material.dart';
import '../models/flashcard_item.dart';
import '../models/generated_set.dart';
import '../models/quiz_question_item.dart';
import '../widgets/flashcard_edit_dialog.dart';
import '../widgets/question_edit_dialog.dart';

class AiDraftReviewScreen extends StatefulWidget {
  final GeneratedSet generatedSet;
  final List<FlashcardItem>? flashcards;
  final List<QuizQuestionItem>? quizQuestions;
  final Future<void> Function() onPublish;

  const AiDraftReviewScreen({
    super.key,
    required this.generatedSet,
    this.flashcards,
    this.quizQuestions,
    required this.onPublish,
  });

  @override
  State<AiDraftReviewScreen> createState() => _AiDraftReviewScreenState();
}

class _AiDraftReviewScreenState extends State<AiDraftReviewScreen> {
  late List<FlashcardItem> _cards;
  late List<QuizQuestionItem> _questions;
  bool _isPublishing = false;
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.flashcards ?? []);
    _questions = List.from(widget.quizQuestions ?? []);
    _isPublished = widget.generatedSet.isPublished;
  }

  void _deleteCard(int index) {
    setState(() => _cards.removeAt(index));
  }

  void _deleteQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  Future<void> _handlePublish() async {
    setState(() => _isPublishing = true);
    try {
      await widget.onPublish();
      setState(() => _isPublished = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã phát hành bài ôn tập thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phát hành: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuiz = widget.generatedSet.isQuiz;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.generatedSet.title),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isPublished ? Colors.green.shade100 : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _isPublished ? 'ĐÃ PHÁT HÀNH' : 'BẢN NHÁP (DRAFT)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isPublished ? Colors.green.shade800 : Colors.amber.shade900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isQuiz ? _buildQuizList(theme) : _buildFlashcardList(theme),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.publish_rounded),
            label: _isPublishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isPublished ? 'Đã phát hành' : 'Phát hành cho phòng học (Publish)'),
            onPressed: (_isPublishing || _isPublished) ? null : _handlePublish,
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardList(ThemeData theme) {
    if (_cards.isEmpty) {
      return const Center(child: Text('Không còn thẻ nào trong danh sách.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Thẻ #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (!_isPublished)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => FlashcardEditDialog(
                                  flashcard: card,
                                  onSave: (updated) {
                                    setState(() => _cards[index] = updated);
                                  },
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteCard(index),
                          ),
                        ],
                      ),
                  ],
                ),
                const Divider(),
                Text('Mặt trước: ${card.frontText}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Mặt sau: ${card.backText}', style: TextStyle(color: Colors.grey.shade800)),
                if (card.explanation != null) ...[
                  const SizedBox(height: 6),
                  Text('Giải thích: ${card.explanation}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizList(ThemeData theme) {
    if (_questions.isEmpty) {
      return const Center(child: Text('Không còn câu hỏi nào trong danh sách.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final q = _questions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Câu hỏi #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (!_isPublished)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => QuestionEditDialog(
                                  question: q,
                                  onSave: (updated) {
                                    setState(() => _questions[index] = updated);
                                  },
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteQuestion(index),
                          ),
                        ],
                      ),
                  ],
                ),
                const Divider(),
                Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(q.options.length, (optIdx) {
                  final isCorrect = optIdx == q.correctIndex;
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
                        Expanded(child: Text(q.options[optIdx])),
                        if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ],
                    ),
                  );
                }),
                if (q.explanation != null) ...[
                  const SizedBox(height: 6),
                  Text('Giải thích: ${q.explanation}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
