import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../documents/models/document_item.dart';
import '../../documents/services/document_service.dart';
import '../models/generated_set.dart';
import '../services/ai_generator_service.dart';
import '../widgets/generated_sets_list_widget.dart';
import 'ai_draft_review_screen.dart';
import 'generate_content_dialog.dart';
import 'published_set_detail_screen.dart';

final roomGeneratedSetsProvider =
    FutureProvider.family<List<GeneratedSet>, String>((ref, roomId) async {
  final service = ref.watch(aiGeneratorServiceProvider);
  return service.fetchSets(roomId);
});

class RoomLearningContentScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String? currentUserId;
  final bool isMentor;

  const RoomLearningContentScreen({
    super.key,
    required this.roomId,
    this.currentUserId,
    this.isMentor = false,
  });

  @override
  ConsumerState<RoomLearningContentScreen> createState() => _RoomLearningContentScreenState();
}

class _RoomLearningContentScreenState extends ConsumerState<RoomLearningContentScreen> {
  void _openSet(GeneratedSet set) {
    if (set.isDraft) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiDraftReviewScreen(
            generatedSet: set,
            onPublish: () async {
              final service = ref.read(aiGeneratorServiceProvider);
              await service.publishSet(set.id);
              ref.invalidate(roomGeneratedSetsProvider(widget.roomId));
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublishedSetDetailScreen(set: set),
        ),
      );
    }
  }

  Future<void> _openGenerateDialog(List<DocumentItem> availableDocs) async {
    AiGeneratedResult? generatedResult;
    final service = ref.read(aiGeneratorServiceProvider);

    final didGenerate = await showDialog<bool>(
      context: context,
      builder: (ctx) => GenerateContentDialog(
        availableDocuments: availableDocs,
        onGenerate: ({
          required documentIds,
          required contentType,
          required count,
          required difficulty,
          topic,
        }) async {
          final docSummary = availableDocs
              .where((d) => documentIds.contains(d.id))
              .map((d) => '${d.fileName}${d.topic != null ? " (${d.topic})" : ""}')
              .join('; ');
          generatedResult = await service.generateContent(
            roomId: widget.roomId,
            createdBy: widget.currentUserId ?? 'current_user',
            title: '${contentType == "quiz" ? "Bài trắc nghiệm" : "Bộ thẻ"} (${difficulty.toUpperCase()})',
            contentType: contentType,
            count: count,
            difficulty: difficulty,
            topic: topic,
            documentIds: documentIds,
            documentContext: docSummary.isNotEmpty
                ? docSummary
                : 'Tài liệu học tập được chọn trong phòng học TLU.',
          );

          ref.invalidate(roomGeneratedSetsProvider(widget.roomId));
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
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(roomGeneratedSetsProvider(widget.roomId));
    final docsAsync = ref.watch(roomDocumentsProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho nội dung ôn tập AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(roomGeneratedSetsProvider(widget.roomId)),
          ),
        ],
      ),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi tải nội dung: $err')),
        data: (sets) {
          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 56, color: Colors.amber.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có bộ đề nào được tạo trong phòng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nhấn nút bên dưới để tạo bài Quiz hoặc Flashcard tự động.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: GeneratedSetsListWidget(
              sets: sets,
              onSelectSet: _openSet,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Tạo bằng AI'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        onPressed: () {
          final docs = docsAsync.asData?.value ?? [];
          _openGenerateDialog(docs);
        },
      ),
    );
  }
}
