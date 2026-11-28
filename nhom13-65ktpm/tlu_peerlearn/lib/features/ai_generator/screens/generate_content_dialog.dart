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
  void initState() {
    super.initState();
    // Auto pre-select when user opened dialog with 1-2 pre-selected docs
    if (widget.availableDocuments.isNotEmpty && widget.availableDocuments.length <= 2) {
      for (final d in widget.availableDocuments) {
        _selectedDocIds.add(d.id);
      }
    }
  }

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade700],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tạo nội dung ôn tập bằng AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Select documents (1-2 docs BR-04)
              Text(
                'Chọn 1 hoặc 2 tài liệu nguồn (tối đa 2):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              if (widget.availableDocuments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Phòng chưa có tài liệu nào. Vui lòng tải lên tài liệu trước.',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                )
              else
                ...widget.availableDocuments.map((doc) {
                  final isSelected = _selectedDocIds.contains(doc.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade200,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CheckboxListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(
                          doc.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          '${doc.fileType.toUpperCase()} • ${doc.formattedFileSize}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
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
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 14),

              // Content Type
              Text(
                'Loại nội dung ôn tập:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),

              // Count slider (5-20)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Số lượng tạo:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade800),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_count.round()} câu/thẻ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
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
              const SizedBox(height: 4),

              // Difficulty
              Text(
                'Độ khó:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 6),
              InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _difficulty,
                    items: const [
                      DropdownMenuItem(value: 'basic', child: Text('Cơ bản (Nhận biết & Thông hiểu)')),
                      DropdownMenuItem(value: 'medium', child: Text('Trung bình (Vận dụng)')),
                      DropdownMenuItem(value: 'advanced', child: Text('Nâng cao (Vận dụng cao)')),
                    ],
                    onChanged: (val) => setState(() => _difficulty = val!),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Topic
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  labelText: 'Chủ đề trọng tâm (tùy chọn)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  prefixIcon: const Icon(Icons.topic_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome, size: 17),
          label: const Text('Bắt đầu tạo'),
        ),
      ],
    );
  }
}
