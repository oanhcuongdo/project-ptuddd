import 'package:flutter/material.dart';
import '../models/quiz_question_item.dart';

class QuestionEditDialog extends StatefulWidget {
  final QuizQuestionItem question;
  final ValueChanged<QuizQuestionItem> onSave;

  const QuestionEditDialog({
    super.key,
    required this.question,
    required this.onSave,
  });

  @override
  State<QuestionEditDialog> createState() => _QuestionEditDialogState();
}

class _QuestionEditDialogState extends State<QuestionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qTextController;
  late TextEditingController _explController;
  late List<TextEditingController> _optionControllers;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    _qTextController = TextEditingController(text: widget.question.questionText);
    _explController = TextEditingController(text: widget.question.explanation ?? '');
    _correctIndex = widget.question.correctIndex;
    _optionControllers = List.generate(4, (i) {
      final text = i < widget.question.options.length ? widget.question.options[i] : '';
      return TextEditingController(text: text);
    });
  }

  @override
  void dispose() {
    _qTextController.dispose();
    _explController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.question.copyWith(
      questionText: _qTextController.text.trim(),
      options: _optionControllers.map((c) => c.text.trim()).toList(),
      correctIndex: _correctIndex,
      explanation: _explController.text.trim().isEmpty ? null : _explController.text.trim(),
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa câu hỏi'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _qTextController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nội dung câu hỏi *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống câu hỏi' : null,
              ),
              const SizedBox(height: 12),
              const Text('4 phương án lựa chọn (chọn đáp án đúng):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Chọn làm đáp án đúng',
                        icon: Icon(
                          _correctIndex == i
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _correctIndex == i ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => setState(() => _correctIndex = i),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[i],
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Phương án ${String.fromCharCode(65 + i)}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập phương án' : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              TextFormField(
                controller: _explController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Giải thích chi tiết (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Lưu thay đổi'),
        ),
      ],
    );
  }
}
