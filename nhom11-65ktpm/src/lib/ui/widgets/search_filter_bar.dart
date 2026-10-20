import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/document_filter.dart';
import '../../domain/models/document_type.dart';
import '../../state/document_provider.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({super.key});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final filter = provider.filter;
    final subjects = provider.subjects;

    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => provider.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bài giảng, bài tập, ghi chú...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        // Filter Chips Bar (Document Type & Subject & Sort)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // All Chip
              FilterChip(
                label: const Text('Tất cả'),
                selected: filter.docType == null && filter.subjectFk == null,
                onSelected: (_) {
                  provider.setDocTypeFilter(null);
                  provider.setSubjectFilter(null);
                },
              ),
              const SizedBox(width: 8),
              // Document Type Chips
              ...DocumentType.values.map((type) {
                final isSelected = filter.docType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      provider.setDocTypeFilter(selected ? type : null);
                    },
                  ),
                );
              }),
              // Subject Dropdown Chip
              PopupMenuButton<String?>(
                child: Chip(
                  avatar: const Icon(Icons.subject, size: 16),
                  label: Text(
                    filter.subjectFk != null
                        ? (provider.subjectMap[filter.subjectFk]?.name ?? 'Môn học')
                        : 'Môn học',
                  ),
                  deleteIcon: filter.subjectFk != null ? const Icon(Icons.close, size: 16) : null,
                  onDeleted: filter.subjectFk != null
                      ? () => provider.setSubjectFilter(null)
                      : null,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('Tất cả môn học'),
                  ),
                  ...subjects.map(
                    (s) => PopupMenuItem(
                      value: s.subjectPk,
                      child: Text('${s.code} - ${s.name}'),
                    ),
                  ),
                ],
                onSelected: (val) => provider.setSubjectFilter(val),
              ),
              const SizedBox(width: 8),
              // Sort Menu
              PopupMenuButton<DocumentSortBy>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sắp xếp',
                initialValue: filter.sortBy,
                onSelected: (sortBy) => provider.setSortBy(sortBy),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: DocumentSortBy.modifiedDesc,
                    child: Text('Cập nhật mới nhất'),
                  ),
                  PopupMenuItem(
                    value: DocumentSortBy.createdDesc,
                    child: Text('Ngày tạo mới nhất'),
                  ),
                  PopupMenuItem(
                    value: DocumentSortBy.titleAsc,
                    child: Text('Tiêu đề A-Z'),
                  ),
                  PopupMenuItem(
                    value: DocumentSortBy.priorityDesc,
                    child: Text('Độ ưu tiên cao nhất'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
