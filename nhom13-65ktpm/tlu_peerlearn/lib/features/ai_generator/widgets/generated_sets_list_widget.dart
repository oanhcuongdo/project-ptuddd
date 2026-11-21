import 'package:flutter/material.dart';
import '../models/generated_set.dart';

class GeneratedSetsListWidget extends StatefulWidget {
  final List<GeneratedSet> sets;
  final void Function(GeneratedSet set)? onSelectSet;

  const GeneratedSetsListWidget({
    super.key,
    required this.sets,
    this.onSelectSet,
  });

  @override
  State<GeneratedSetsListWidget> createState() => _GeneratedSetsListWidgetState();
}

class _GeneratedSetsListWidgetState extends State<GeneratedSetsListWidget> {
  String _filter = 'all'; // 'all', 'quiz', 'flashcard', 'draft', 'published'

  @override
  Widget build(BuildContext context) {
    final filtered = widget.sets.where((s) {
      if (_filter == 'quiz') return s.isQuiz;
      if (_filter == 'flashcard') return s.isFlashcard;
      if (_filter == 'draft') return s.isDraft;
      if (_filter == 'published') return s.isPublished;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('all', 'Tất cả (${widget.sets.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('quiz', 'Trắc nghiệm'),
              const SizedBox(width: 8),
              _buildFilterChip('flashcard', 'Flashcard'),
              const SizedBox(width: 8),
              _buildFilterChip('published', 'Đã phát hành'),
              const SizedBox(width: 8),
              _buildFilterChip('draft', 'Bản nháp'),
            ],
          ),
        ),

        // List
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Không có bộ đề nào phù hợp',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              final isPublished = item.isPublished;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isQuiz ? Colors.blue.shade100 : Colors.purple.shade100,
                    child: Icon(
                      item.isQuiz ? Icons.quiz_outlined : Icons.style_outlined,
                      color: item.isQuiz ? Colors.blue.shade800 : Colors.purple.shade800,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.topic ?? "Chung"} • Độ khó: ${item.difficulty}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublished ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPublished ? Colors.green.shade300 : Colors.amber.shade400,
                      ),
                    ),
                    child: Text(
                      isPublished ? 'Đã duyệt' : 'Bản nháp',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPublished ? Colors.green.shade800 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                  onTap: () => widget.onSelectSet?.call(item),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = key),
    );
  }
}
