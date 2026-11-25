import 'package:flutter/material.dart';
import '../models/flashcard_item.dart';

class FlashcardEditDialog extends StatefulWidget {
  final FlashcardItem flashcard;
  final ValueChanged<FlashcardItem> onSave;

  const FlashcardEditDialog({
    super.key,
    required this.flashcard,
    required this.onSave,
  });

  @override
  State<FlashcardEditDialog> createState() => _FlashcardEditDialogState();
}

class _FlashcardEditDialogState extends State<FlashcardEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _frontController;
  late TextEditingController _backController;
  late TextEditingController _explController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.flashcard.frontText);
    _backController = TextEditingController(text: widget.flashcard.backText);
    _explController = TextEditingController(text: widget.flashcard.explanation ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _explController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.flashcard.copyWith(
      frontText: _frontController.text.trim(),
      backText: _backController.text.trim(),
      explanation: _explController.text.trim().isEmpty ? null : _explController.text.trim(),
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa thẻ ghi nhớ (Flashcard)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _frontController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mặt trước (Thuật ngữ / Câu hỏi) *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống mặt trước' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _backController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mặt sau (Định nghĩa / Câu trả lời) *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống mặt sau' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _explController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Giải thích bổ sung (tùy chọn)',
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
