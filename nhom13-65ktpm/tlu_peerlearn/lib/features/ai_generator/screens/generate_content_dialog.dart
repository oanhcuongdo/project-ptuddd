import 'package:flutter/material.dart';
import '../../documents/models/document_item.dart';
import '../services/gemini_schema_helper.dart';

class GenerateContentDialog extends StatefulWidget {
  final List<DocumentItem> availableDocuments;
  final Future<void> Function({
    required List<String> documentIds,
    required String contentType, // 'flashcard' | 'quiz'
    required int count,
    required String difficulty,
    String? topic,
  }) onGenerate;

  const GenerateContentDialog({
    super.key,
    required this.availableDocuments,
    required this.onGenerate,
  });

  @override
  State<GenerateContentDialog> createState() => _GenerateContentDialogState();
}

class _GenerateContentDialogState extends State<GenerateContentDialog> {
  final Set<String> _selectedDocIds = {};
  String _contentType = 'quiz';
  double _count = 10;
  String _difficulty = 'medium';
  final _topicController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final docError = GeminiSchemaHelper.validateSelectedDocuments(_selectedDocIds.toList());
    if (docError != null) {
      setState(() => _errorMessage = docError);
      return;
    }

    final countError = GeminiSchemaHelper.validateItemCount(_count.round());
    if (countError != null) {
      setState(() => _errorMessage = countError);
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await widget.onGenerate(
        documentIds: _selectedDocIds.toList(),
        contentType: _contentType,
        count: _count.round(),
        difficulty: _difficulty,
        topic: _topicController.text.trim().isEmpty ? null : _topicController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Lỗi tạo nội dung: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo nội dung ôn tập bằng AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Select documents (1-2 docs BR-04)
            Text(
              'Chọn 1 hoặc 2 tài liệu nguồn (tối đa 2):',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 6),
            if (widget.availableDocuments.isEmpty)
              Text(
                'Phòng chưa có tài liệu nào. Vui lòng tải lên tài liệu trước.',
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              )
            else
              ...widget.availableDocuments.map((doc) {
                final isSelected = _selectedDocIds.contains(doc.id);
                return CheckboxListTile(
                  dense: true,
                  title: Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(doc.formattedFileSize),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        if (_selectedDocIds.length < 2) {
                          _selectedDocIds.add(doc.id);
                        }
                      } else {
                        _selectedDocIds.remove(doc.id);
                      }
                    });
                  },
                );
              }),
            const SizedBox(height: 12),

            // Content Type
            const Text('Loại nội dung ôn tập:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'quiz',
                  label: Text('Trắc nghiệm (Quiz)'),
                  icon: Icon(Icons.quiz_outlined),
                ),
                ButtonSegment<String>(
                  value: 'flashcard',
                  label: Text('Flashcard'),
                  icon: Icon(Icons.style_outlined),
                ),
              ],
              selected: {_contentType},
              onSelectionChanged: (set) => setState(() => _contentType = set.first),
            ),
            const SizedBox(height: 12),

            // Count slider (5-20)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Số lượng tạo:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_count.round()} câu/thẻ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            Slider(
              value: _count,
              min: 5,
              max: 20,
              divisions: 15,
              label: '${_count.round()}',
              onChanged: (val) => setState(() => _count = val),
            ),

            // Difficulty
            const Text('Độ khó:', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              isExpanded: true,
              value: _difficulty,
              items: const [
                DropdownMenuItem(value: 'basic', child: Text('Cơ bản (Nhận biết & Thông hiểu)')),
                DropdownMenuItem(value: 'medium', child: Text('Trung bình (Vận dụng)')),
                DropdownMenuItem(value: 'advanced', child: Text('Nâng cao (Vận dụng cao)')),
              ],
              onChanged: (val) => setState(() => _difficulty = val!),
            ),
            const SizedBox(height: 8),

            // Topic
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Chủ đề trọng tâm (tùy chọn)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Bắt đầu tạo'),
        ),
      ],
    );
  }
}
