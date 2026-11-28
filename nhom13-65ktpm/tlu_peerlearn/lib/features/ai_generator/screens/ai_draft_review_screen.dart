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
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.generatedSet.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isPublished ? Colors.green.shade300 : Colors.amber.shade400,
              ),
            ),
            child: Center(
              child: Text(
                _isPublished ? 'ĐÃ PHÁT HÀNH' : 'BẢN NHÁP (DRAFT)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _isPublished ? Colors.green.shade800 : Colors.amber.shade900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: isQuiz ? _buildQuizList(theme) : _buildFlashcardList(theme),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _isPublished ? Colors.green.shade600 : const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_isPublished ? Icons.check_circle_rounded : Icons.publish_rounded),
                    label: _isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isPublished ? 'Đã phát hành' : 'Phát hành cho phòng học (Publish)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                    onPressed: (_isPublishing || _isPublished) ? null : _handlePublish,
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Thẻ #${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                    if (!_isPublished)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF)),
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1D4ED8)),
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
                          const SizedBox(width: 6),
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2)),
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 18),
                            onPressed: () => _deleteCard(index),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Mặt trước: ${card.frontText}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Mặt sau: ${card.backText}',
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.5),
                  ),
                ),
                if (card.explanation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Giải thích: ${card.explanation}',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final q = _questions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Câu hỏi #${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                    if (!_isPublished)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF)),
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1D4ED8)),
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
                          const SizedBox(width: 6),
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2)),
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 18),
                            onPressed: () => _deleteQuestion(index),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  q.questionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(q.options.length, (optIdx) {
                  final isCorrect = optIdx == q.correctIndex;
                  final cleanOption = q.options[optIdx].replaceFirst(RegExp(r'^[A-Da-d]\.\s*'), '');
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCorrect ? Colors.green.shade400 : Colors.grey.shade200,
                        width: isCorrect ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + optIdx)}. ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isCorrect ? Colors.green.shade800 : const Color(0xFF475569),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            cleanOption,
                            style: TextStyle(
                              color: isCorrect ? Colors.green.shade900 : const Color(0xFF1E293B),
                              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 18),
                      ],
                    ),
                  );
                }),
                if (q.explanation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Giải thích: ${q.explanation}',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
