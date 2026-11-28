import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/quiz_scores_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/ai_client.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/quiz_question.dart';
import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({
    required this.notesCubit,
    required this.scoresDao,
    required this.aiClient,
    super.key,
  });

  final NotesCubit notesCubit;
  final QuizScoresDao scoresDao;
  final AiClient aiClient;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  String? _selectedNoteId;
  List<QuizQuestion> _questions = <QuizQuestion>[];
  final Map<int, int> _answers = <int, int>{};
  bool _submitted = false;
  bool _generating = false;
  int _generationId = 0;
  String? _generationError;
  String? _submissionError;
  String? _historyError;
  List<QuizScoreRow> _history = <QuizScoreRow>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final rows = await widget.scoresDao.getAll();
      if (mounted) {
        setState(() {
          _history = rows;
          _historyError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _historyError = '$error');
    }
  }

  bool _isLongEnough(String content) =>
      content
          .trim()
          .split(RegExp(r'\s+'))
          .where((String word) => word.isNotEmpty)
          .length >=
      20;

  List<QuizQuestion> _generateDemoQuestions(Note note) {
    final sentences = note.content
        .replaceAll('\n', ' ')
        .split(RegExp(r'[.!?\n]+'))
        .map((String value) => value.trim())
        .where((String value) => value.split(RegExp(r'\s+')).length >= 4)
        .toList();
    if (sentences.isEmpty) return <QuizQuestion>[];

    final random = Random(note.id.hashCode);
    final pool = <String>{
      for (final sentence in sentences)
        ...sentence
            .replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '')
            .split(RegExp(r'\s+'))
            .where((String word) => word.length >= 4),
    }.toList();

    final result = <QuizQuestion>[];
    for (var index = 0; index < 5; index++) {
      final sentence = sentences[index % sentences.length];
      final words = sentence
          .replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '')
          .split(RegExp(r'\s+'))
          .where((String word) => word.length >= 4)
          .toList();
      if (words.isEmpty) continue;
      words.shuffle(random);
      final answer = words.first;
      final distractors = pool.where((String word) => word != answer).toList()
        ..shuffle(random);
      final options = <String>[answer, ...distractors.take(3)]..shuffle(random);
      if (options.length < 4) continue;
      final prompt = sentence.replaceFirst(
        RegExp(RegExp.escape(answer), caseSensitive: false),
        '______',
      );
      result.add(
        QuizQuestion(
          question: 'Điền từ còn thiếu: $prompt',
          options: options,
          correctIndex: options.indexOf(answer),
          explanation: 'Từ “$answer” có trong câu gốc: $sentence',
        ),
      );
    }
    return result;
  }

  Future<void> _selectNote(Note note) async {
    final requestId = ++_generationId;
    setState(() {
      _selectedNoteId = note.id;
      _questions = <QuizQuestion>[];
      _answers.clear();
      _submitted = false;
      _generating = false;
      _generationError = null;
      _submissionError = null;
    });
    if (!_isLongEnough(note.content)) {
      setState(
        () => _generationError =
            'Ghi chú quá ngắn. Cần ít nhất 20 từ để tạo đề có ý nghĩa.',
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final questions = widget.aiClient.isDemo
          ? _generateDemoQuestions(note)
          : (await widget.aiClient.generateQuiz(
              text: note.content,
              noteId: note.id,
              title: note.displayTitle,
            )).map(QuizQuestion.fromJson).toList();
      if (!mounted || requestId != _generationId) return;
      setState(() {
        _questions = questions;
        _generating = false;
        if (questions.isEmpty) {
          _generationError = 'Chưa thể tạo đủ câu hỏi từ ghi chú này. Hãy bổ sung nội dung rồi thử lại.';
        }
      });
    } on AiFailure catch (error) {
      if (mounted && requestId == _generationId) {
        setState(() {
          _generating = false;
          _generationError = error.message;
        });
      }
    } on FormatException catch (error) {
      if (mounted && requestId == _generationId) {
        setState(() {
          _generating = false;
          _generationError = 'Dữ liệu câu hỏi không hợp lệ: ${error.message}';
        });
      }
    } on Object catch (error) {
      if (mounted && requestId == _generationId) {
        setState(() {
          _generating = false;
          _generationError = 'Không tạo được đề trắc nghiệm: $error';
        });
      }
    }
  }

  Future<void> _submit(Note note) async {
    final correct = _questions.indexed.where((entry) {
      final index = entry.$1;
      final question = entry.$2;
      return _answers[index] == question.correctIndex;
    }).length;

    try {
      await widget.scoresDao.insertScore(
        QuizScoresCompanion.insert(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          noteId: note.id,
          noteTitle: Value(note.displayTitle),
          correctAnswers: correct,
          totalQuestions: _questions.length,
          completedAt: Value(DateTime.now()),
        ),
      );
      if (mounted) {
        setState(() {
          _submitted = true;
          _submissionError = null;
        });
      }
      await _loadHistory();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _submissionError = 'Không lưu được điểm: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trắc nghiệm từ ghi chú')),
      body: BlocBuilder<NotesCubit, NotesState>(
        bloc: widget.notesCubit,
        builder: (_, NotesState state) {
          final notes = state.notes
              .where((Note note) => note.content.trim().isNotEmpty)
              .toList();
          final matchingNotes = notes
              .where((Note item) => item.id == _selectedNoteId)
              .toList();
          final note = matchingNotes.isEmpty ? null : matchingNotes.first;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: _selectedNoteId,
                decoration: const InputDecoration(
                  labelText: 'Chọn ghi chú để tạo đề',
                  border: OutlineInputBorder(),
                ),
                items: notes
                    .map(
                      (Note item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          item.displayTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (String? id) {
                  if (id == null) return;
                  final selected = notes.firstWhere((item) => item.id == id);
                  unawaited(_selectNote(selected));
                },
              ),
              if (widget.aiClient.isDemo)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Chế độ xem trước: câu hỏi mẫu tạo tại máy.'),
                ),
              const SizedBox(height: 16),
              if (_generating) ...<Widget>[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('AI đang tạo câu hỏi…'),
              ],
              if (_generationError != null) ...<Widget>[
                _QuizMessage(text: _generationError!),
                if (note != null && _isLongEnough(note.content))
                  OutlinedButton.icon(
                    onPressed: () => unawaited(_selectNote(note)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử tạo lại'),
                  ),
              ] else if (_selectedNoteId == null)
                const _QuizMessage(
                  text: 'Chọn ghi chú đủ nội dung để bắt đầu tạo đề.',
                ),
              for (var i = 0; i < _questions.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Câu ${i + 1}: ${_questions[i].question}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        RadioGroup<int>(
                          groupValue: _answers[i],
                          onChanged: _submitted
                              ? (_) {}
                              : (int? value) => setState(() {
                                  if (value != null) _answers[i] = value;
                                }),
                          child: Column(
                            children: <Widget>[
                              for (
                                var j = 0;
                                j < _questions[i].options.length;
                                j++
                              )
                                RadioListTile<int>(
                                  value: j,
                                  title: Text(_questions[i].options[j]),
                                ),
                            ],
                          ),
                        ),
                        if (_submitted) ...<Widget>[
                          Text(
                            _answers[i] == _questions[i].correctIndex
                                ? 'Đúng'
                                : 'Sai — đáp án: '
                                      '${_questions[i].options[_questions[i].correctIndex]}',
                            style: TextStyle(
                              color: _answers[i] == _questions[i].correctIndex
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Giải thích: ${_questions[i].explanation}'),
                        ],
                      ],
                    ),
                  ),
                ),
              if (_submitted)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Kết quả: ${_answers.entries.where((MapEntry<int, int> answer) => answer.value == _questions[answer.key].correctIndex).length}/${_questions.length} câu đúng',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              if (_submissionError != null)
                _QuizMessage(text: _submissionError!),
              if (_questions.isNotEmpty)
                FilledButton(
                  onPressed:
                      _submitted ||
                          _answers.length != _questions.length ||
                          note == null
                      ? null
                      : () => _submit(note),
                  child: const Text('Nộp bài và lưu điểm'),
                ),
              const SizedBox(height: 24),
              Text(
                'Lịch sử điểm',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_historyError != null)
                _QuizMessage(
                  text: 'Không đọc được lịch sử điểm: $_historyError',
                ),
              if (_history.isEmpty && _historyError == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Chưa có điểm nào'),
                ),
              for (final score in _history)
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: Text(score.noteTitle),
                  subtitle: Text(
                    '${score.correctAnswers}/${score.totalQuestions} câu đúng',
                  ),
                  trailing: Text(
                    '${((score.correctAnswers * 100) / score.totalQuestions).round()}%',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuizMessage extends StatelessWidget {
  const _QuizMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
