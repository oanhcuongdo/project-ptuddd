import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/document_item.dart';
import '../models/document_sort_option.dart';
import '../services/document_service.dart';
import '../utils/docx_byte_extractor.dart';
import '../utils/text_extractor.dart';
import '../widgets/document_card.dart';
import '../widgets/document_quota_card.dart';
import '../widgets/document_upload_dialog.dart';
import 'document_preview_screen.dart';
import '../../ai_generator/screens/ai_draft_review_screen.dart';
import '../../ai_generator/screens/generate_content_dialog.dart';
import '../../ai_generator/screens/room_learning_content_screen.dart';
import '../../ai_generator/services/ai_generator_service.dart';
import '../../practice_stats/services/practice_service.dart';

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

  Future<void> _openDirectAiGeneration(List<DocumentItem> selectedDocs) async {
    AiGeneratedResult? generatedResult;
    final service = ref.read(aiGeneratorServiceProvider);

    final didGenerate = await showDialog<bool>(
      context: context,
      builder: (ctx) => GenerateContentDialog(
        availableDocuments: selectedDocs,
        onGenerate: ({
          required documentIds,
          required contentType,
          required count,
          required difficulty,
          topic,
        }) async {
          final chosenDocs = selectedDocs
              .where((d) => documentIds.contains(d.id))
              .toList();
          final extracted = await _extractContextFromDocuments(chosenDocs);
          final docSummary = chosenDocs
              .map((d) => '${d.fileName}${d.topic != null ? " (${d.topic})" : ""}')
              .join('; ');
          final contextText = extracted.isNotEmpty
              ? extracted
              : (docSummary.isNotEmpty ? docSummary : 'Tài liệu phòng học TLU.');
          generatedResult = await service.generateContent(
            roomId: widget.roomId,
            createdBy: widget.currentUserId ?? 'current_user',
            title: '${contentType == "quiz" ? "Bài trắc nghiệm" : "Bộ thẻ"} (${difficulty.toUpperCase()})',
            contentType: contentType,
            count: count,
            difficulty: difficulty,
            topic: topic,
            documentIds: documentIds,
            documentContext: contextText,
          );
          ref.invalidate(roomGeneratedSetsProvider(widget.roomId));
          ref.invalidate(roomPublishedSetsProvider(widget.roomId));
        },
      ),
    );

    if (didGenerate == true && generatedResult != null && mounted) {
      final result = generatedResult!;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiDraftReviewScreen(
            generatedSet: result.set,
            flashcards: result.flashcards,
            quizQuestions: result.questions,
            onPublish: () async {
              await service.publishSet(result.set.id);
              ref.invalidate(roomGeneratedSetsProvider(widget.roomId));
              ref.invalidate(roomPublishedSetsProvider(widget.roomId));
            },
          ),
        ),
      );
      ref.invalidate(roomGeneratedSetsProvider(widget.roomId));
      ref.invalidate(roomPublishedSetsProvider(widget.roomId));
    }
  }

  Future<String> _extractContextFromDocuments(List<DocumentItem> docs) async {
    final buffer = StringBuffer();
    for (final doc in docs) {
      if (doc.fileUrl.isEmpty || !doc.fileUrl.startsWith('http')) continue;
      try {
        final res = await http.get(Uri.parse(doc.fileUrl));
        if (res.statusCode != 200 || res.bodyBytes.isEmpty) continue;
        final lower = doc.fileName.toLowerCase();
        String text = '';
        if (lower.endsWith('.docx')) {
          text = await DocxByteExtractor.extractTextFromDocxBytes(res.bodyBytes);
        }
        if (text.trim().isNotEmpty) {
          buffer.writeln('--- ${doc.fileName} ---');
          buffer.writeln(TextExtractor.cleanText(text));
        }
      } catch (_) {
        // Skip unreadable document and continue with remaining ones
      }
    }
    return TextExtractor.truncateToLimit(buffer.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(roomDocumentsProvider(widget.roomId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Column(
        children: [
          // Quota summary card
          docsAsync.maybeWhen(
            data: (docs) => docs.isNotEmpty ? DocumentQuotaCard(documents: docs) : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),

          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tài liệu...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: PopupMenuButton<DocumentSortOption>(
                    icon: const Icon(Icons.sort_rounded, size: 20),
                    tooltip: 'Sắp xếp tài liệu',
                    onSelected: (opt) => setState(() => _sortOption = opt),
                    itemBuilder: (context) => DocumentSortOption.values
                        .map((opt) => PopupMenuItem(value: opt, child: Text(opt.label)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: _selectedFilter != 'all' ? const Color(0xFFE3F2FD) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFilter != 'all' ? const Color(0xFF1976D2) : Colors.grey.shade200,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: _selectedFilter != 'all' ? const Color(0xFF0D47A1) : null,
                    ),
                    tooltip: 'Lọc theo định dạng',
                    onSelected: (val) => setState(() => _selectedFilter = val),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'all', child: Text('Tất cả định dạng')),
                      PopupMenuItem(value: 'pdf', child: Text('Chỉ tệp PDF')),
                      PopupMenuItem(value: 'docx', child: Text('Chỉ tệp Word (.docx)')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter chips indicator
          if (_selectedFilter != 'all')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Chip(
                    backgroundColor: const Color(0xFFE3F2FD),
                    side: BorderSide.none,
                    label: Text(
                      _selectedFilter.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    onDeleted: () => setState(() => _selectedFilter = 'all'),
                  ),
                ],
              ),
            ),

          // Selection bar for AI generation (Mentor only)
          if (widget.isMentor && _selectedForAi.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade50, Colors.orange.shade50],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade400),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade700.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.amber.shade900, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đã chọn ${_selectedForAi.length}/2 tài liệu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedForAi.clear()),
                    child: const Text('Bỏ chọn'),
                  ),
                  const SizedBox(width: 4),
                  docsAsync.maybeWhen(
                    data: (docs) => FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Tạo bài AI'),
                      onPressed: () {
                        final selected = docs.where((d) => _selectedForAi.contains(d.id)).toList();
                        if (widget.onGenerateAi != null) {
                          widget.onGenerateAi!(selected);
                        } else {
                          _openDirectAiGeneration(selected);
                        }
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            )
          else if (widget.isMentor)
            docsAsync.maybeWhen(
              data: (docs) => docs.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                      child: Row(
                        children: [
                          Icon(Icons.tips_and_updates_outlined, size: 15, color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Mẹo: Chạm chọn 1–2 tài liệu bên dưới để AI sinh trắc nghiệm hoặc flashcard.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.folder_open_rounded,
                              size: 46,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có tài liệu nào trong phòng học',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tải lên tệp PDF hoặc DOCX để lưu trữ và tạo bài ôn tập bằng AI.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(roomDocumentsProvider(widget.roomId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 84),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final canDelete = widget.isMentor ||
                          (widget.currentUserId != null &&
                              doc.uploadedBy == widget.currentUserId);
                      final isSelected = widget.isMentor && _selectedForAi.contains(doc.id);

                      return DocumentCard(
                        document: doc,
                        showDelete: canDelete,
                        isSelected: isSelected,
                        onDelete: () => _confirmDelete(context, doc),
                        onPreview: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (previewCtx) => DocumentPreviewScreen(
                                document: doc,
                                onGenerateAi: widget.isMentor
                                    ? () {
                                        Navigator.of(previewCtx).pop();
                                        if (widget.onGenerateAi != null) {
                                          widget.onGenerateAi!([doc]);
                                        } else {
                                          _openDirectAiGeneration([doc]);
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          );
                        },
                        onTap: widget.isMentor
                            ? () {
                                // Toggle select for AI generation (max 2 docs)
                                setState(() {
                                  if (_selectedForAi.contains(doc.id)) {
                                    _selectedForAi.remove(doc.id);
                                  } else if (_selectedForAi.length < 2) {
                                    _selectedForAi.add(doc.id);
                                  }
                                });
                              }
                            : null,
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
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Tải lên', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _showUploadDialog(context),
      ),
    );
  }
}
