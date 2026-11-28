import 'package:flutter/material.dart';

import '../../domain/entities/classified_note.dart';
import '../../domain/entities/subject.dart';
import 'subject_color_dot.dart';

/// Lựa chọn trong hộp phân loại: môn học (`null` = không có môn) và tag.
class NoteClassificationResult {
  const NoteClassificationResult({required this.subjectId, required this.tags});

  final String? subjectId;
  final List<String> tags;
}

/// Hộp chọn môn học và tag cho một ghi chú; gõ tên để tạo tag mới.
class NoteClassificationSheet extends StatefulWidget {
  const NoteClassificationSheet({
    required this.note,
    required this.subjects,
    required this.tags,
    super.key,
  });

  final ClassifiedNote note;
  final List<Subject> subjects;
  final List<String> tags;

  static Future<NoteClassificationResult?> show(
    BuildContext context, {
    required ClassifiedNote note,
    required List<Subject> subjects,
    required List<String> tags,
  }) {
    return showModalBottomSheet<NoteClassificationResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          NoteClassificationSheet(note: note, subjects: subjects, tags: tags),
    );
  }

  @override
  State<NoteClassificationSheet> createState() =>
      _NoteClassificationSheetState();
}

class _NoteClassificationSheetState extends State<NoteClassificationSheet> {
  late String? _subjectId = widget.note.subjectId;
  late final List<String> _selected = List<String>.of(widget.note.tags);
  late final List<String> _allTags = <String>{
    ...widget.tags,
    ...widget.note.tags,
  }.toList();
  final TextEditingController _newTag = TextEditingController();

  @override
  void dispose() {
    _newTag.dispose();
    super.dispose();
  }

  void _toggle(String tag, bool selected) {
    setState(() => selected ? _selected.add(tag) : _selected.remove(tag));
  }

  /// Thêm tag mới gõ ở ô nhập (bỏ dấu `#` ở đầu), chọn sẵn tag đó.
  void _addTag() {
    final tag = _newTag.text.trim().replaceFirst(RegExp(r'^#+'), '').trim();
    if (tag.isEmpty) return;
    setState(() {
      if (!_allTags.contains(tag)) _allTags.add(tag);
      if (!_selected.contains(tag)) _selected.add(tag);
      _newTag.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.note.displayTitle, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Môn học', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildSubjects(),
            const SizedBox(height: 16),
            Text('Tag', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildTags(),
            _buildNewTagField(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey<String>('sheet-save'),
                onPressed: () => Navigator.of(context).pop(
                  NoteClassificationResult(
                    subjectId: _subjectId,
                    tags: List<String>.of(_selected),
                  ),
                ),
                child: const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjects() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ChoiceChip(
          key: const ValueKey<String>('sheet-subject-none'),
          label: const Text('Không có môn'),
          selected: _subjectId == null,
          onSelected: (_) => setState(() => _subjectId = null),
        ),
        for (final subject in widget.subjects)
          ChoiceChip(
            key: ValueKey<String>('sheet-subject-${subject.id}'),
            avatar: SubjectColorDot(color: subject.color),
            label: Text(subject.name),
            selected: _subjectId == subject.id,
            onSelected: (_) => setState(() => _subjectId = subject.id),
          ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final tag in _allTags)
          FilterChip(
            key: ValueKey<String>('sheet-tag-$tag'),
            label: Text('#$tag'),
            selected: _selected.contains(tag),
            onSelected: (bool selected) => _toggle(tag, selected),
          ),
      ],
    );
  }

  Widget _buildNewTagField() {
    return TextField(
      key: const ValueKey<String>('sheet-new-tag'),
      controller: _newTag,
      decoration: InputDecoration(
        hintText: 'Thêm tag mới, ví dụ: ôn thi',
        suffixIcon: IconButton(
          key: const ValueKey<String>('sheet-add-tag'),
          tooltip: 'Thêm tag',
          icon: const Icon(Icons.add),
          onPressed: _addTag,
        ),
      ),
      onSubmitted: (_) => _addTag(),
    );
  }
}
