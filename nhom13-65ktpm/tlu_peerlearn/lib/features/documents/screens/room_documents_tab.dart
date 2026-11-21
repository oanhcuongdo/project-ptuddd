import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_item.dart';
import '../models/document_sort_option.dart';
import '../services/document_service.dart';
import '../widgets/document_card.dart';
import '../widgets/document_quota_card.dart';
import '../widgets/document_upload_dialog.dart';

class RoomDocumentsTab extends ConsumerStatefulWidget {
  final String roomId;
  final String? currentUserId;
  final bool isMentor;
  final void Function(List<DocumentItem> selectedDocs)? onGenerateAi;

  const RoomDocumentsTab({
    super.key,
    required this.roomId,
    this.currentUserId,
    this.isMentor = false,
    this.onGenerateAi,
  });

  @override
  ConsumerState<RoomDocumentsTab> createState() => _RoomDocumentsTabState();
}

class _RoomDocumentsTabState extends ConsumerState<RoomDocumentsTab> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'pdf', 'docx'
  DocumentSortOption _sortOption = DocumentSortOption.newest;
  final Set<String> _selectedForAi = {};

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DocumentUploadDialog(
        onUpload: ({required fileName, required bytes, topic}) async {
          final service = ref.read(documentServiceProvider);
          await service.uploadDocument(
            roomId: widget.roomId,
            fileName: fileName,
            bytes: bytes,
            uploadedBy: widget.currentUserId ?? 'current_user',
            topic: topic,
          );
          ref.invalidate(roomDocumentsProvider(widget.roomId));
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DocumentItem doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text('Bạn có chắc chắn muốn xóa "${doc.fileName}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(documentServiceProvider);
      await service.deleteDocument(documentId: doc.id, fileUrl: doc.fileUrl);
      if (!mounted) return;
      ref.invalidate(roomDocumentsProvider(widget.roomId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa tài liệu thành công')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(roomDocumentsProvider(widget.roomId));

    return Scaffold(
      body: Column(
        children: [
          // Quota summary card
          docsAsync.maybeWhen(
            data: (docs) => docs.isNotEmpty ? DocumentQuotaCard(documents: docs) : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),

          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tài liệu...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<DocumentSortOption>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sắp xếp tài liệu',
                  onSelected: (opt) => setState(() => _sortOption = opt),
                  itemBuilder: (context) => DocumentSortOption.values
                      .map((opt) => PopupMenuItem(value: opt, child: Text(opt.label)))
                      .toList(),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Lọc theo định dạng',
                  onSelected: (val) => setState(() => _selectedFilter = val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('Tất cả định dạng')),
                    const PopupMenuItem(value: 'pdf', child: Text('Chỉ tệp PDF')),
                    const PopupMenuItem(value: 'docx', child: Text('Chỉ tệp Word (.docx)')),
                  ],
                ),
              ],
            ),
          ),

          // Filter chips indicator
          if (_selectedFilter != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      _selectedFilter.toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () => setState(() => _selectedFilter = 'all'),
                  ),
                ],
              ),
            ),

          // Selection bar for AI generation
          if (_selectedForAi.isNotEmpty)
            Container(
              color: Colors.amber.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Đã chọn ${_selectedForAi.length}/2 tài liệu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  docsAsync.maybeWhen(
                    data: (docs) => FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800),
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text('Tạo bài AI'),
                      onPressed: () {
                        final selected = docs.where((d) => _selectedForAi.contains(d.id)).toList();
                        widget.onGenerateAi?.call(selected);
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

          // Document list
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Lỗi tải tài liệu: $err'),
              ),
              data: (docs) {
                var filtered = docs.where((d) {
                  final matchesQuery = _searchQuery.isEmpty ||
                      d.fileName.toLowerCase().contains(_searchQuery) ||
                      (d.topic?.toLowerCase().contains(_searchQuery) ?? false);
                  final matchesType = _selectedFilter == 'all' ||
                      d.fileType.toLowerCase() == _selectedFilter;
                  return matchesQuery && matchesType;
                }).toList();

                filtered = _sortOption.sort(filtered);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có tài liệu nào trong phòng học',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(roomDocumentsProvider(widget.roomId));
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final canDelete = widget.isMentor ||
                          (widget.currentUserId != null &&
                              doc.uploadedBy == widget.currentUserId);

                      return DocumentCard(
                        document: doc,
                        showDelete: canDelete,
                        onDelete: () => _confirmDelete(context, doc),
                        onTap: () {
                          // Toggle select for AI generation (max 2 docs BR-04)
                          setState(() {
                            if (_selectedForAi.contains(doc.id)) {
                              _selectedForAi.remove(doc.id);
                            } else if (_selectedForAi.length < 2) {
                              _selectedForAi.add(doc.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tải lên'),
        onPressed: () => _showUploadDialog(context),
      ),
    );
  }
}
