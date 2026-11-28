import 'package:flutter/material.dart';

import '../../domain/entities/note_filter.dart';
import '../../domain/entities/subject.dart';
import 'subject_color_dot.dart';

/// Thanh lọc ghi chú: hàng trên chọn môn học, hàng dưới chọn tag.
class NoteFilterBar extends StatelessWidget {
  const NoteFilterBar({
    required this.subjects,
    required this.tags,
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final List<Subject> subjects;
  final List<String> tags;
  final NoteFilter filter;
  final ValueChanged<NoteFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final allSelected = filter.subjectId == null && !filter.unclassifiedOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ChipRow(
          children: <Widget>[
            ChoiceChip(
              key: const ValueKey<String>('subject-filter-all'),
              label: const Text('Tất cả'),
              selected: allSelected,
              onSelected: (_) => onChanged(filter.withSubject(null)),
            ),
            for (final subject in subjects)
              ChoiceChip(
                key: ValueKey<String>('subject-filter-${subject.id}'),
                avatar: SubjectColorDot(color: subject.color),
                label: Text(subject.name),
                selected: filter.subjectId == subject.id,
                onSelected: (_) => onChanged(filter.withSubject(subject.id)),
              ),
            ChoiceChip(
              key: const ValueKey<String>('subject-filter-none'),
              label: const Text('Chưa phân loại'),
              selected: filter.unclassifiedOnly,
              onSelected: (_) => onChanged(filter.withUnclassifiedOnly()),
            ),
          ],
        ),
        if (tags.isNotEmpty)
          _ChipRow(
            children: <Widget>[
              for (final tag in tags)
                FilterChip(
                  key: ValueKey<String>('tag-filter-$tag'),
                  label: Text('#$tag'),
                  selected: filter.tags.contains(tag),
                  onSelected: (_) => onChanged(filter.toggleTag(tag)),
                ),
              if (filter.tags.isNotEmpty)
                TextButton(
                  key: const ValueKey<String>('tag-filter-clear'),
                  onPressed: () => onChanged(filter.clearTags()),
                  child: const Text('Bỏ lọc tag'),
                ),
            ],
          ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: <Widget>[
          for (final child in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
        ],
      ),
    );
  }
}
