import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../ai_generator/models/generated_set.dart';
import '../models/flashcard_study_item.dart';
import '../services/practice_service.dart';
import '../widgets/flashcard_card.dart';

class FlashcardStudyScreen extends ConsumerStatefulWidget {
  final GeneratedSet generatedSet;
  final String userId;
  final List<FlashcardStudyItem>? initialCards;

  const FlashcardStudyScreen({
    super.key,
    required this.generatedSet,
    required this.userId,
    this.initialCards,
  });

  @override
  ConsumerState<FlashcardStudyScreen> createState() =>
      _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen> {
  List<FlashcardStudyItem> _cards = [];
  bool _isLoading = true;
  bool _onlyUnremembered = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialCards != null) {
      _cards = List.from(widget.initialCards!);
      _isLoading = false;
    } else {
      _loadCards();
    }
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final service = ref.read(practiceServiceProvider);
    final res = await service.fetchFlashcardsWithProgress(
      setId: widget.generatedSet.id,
      userId: widget.userId,
    );
    if (mounted) {
      setState(() {
        _cards = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRemembered(FlashcardStudyItem item) async {
    final newRemembered = !item.isRemembered;
    final cardId = item.flashcard.id;

    setState(() {
      final idx = _cards.indexWhere((c) => c.flashcard.id == cardId);
      if (idx != -1) {
        _cards[idx] = _cards[idx].copyWith(isRemembered: newRemembered);
      }
    });

    final service = ref.read(practiceServiceProvider);
    await service.setFlashcardProgress(
      userId: widget.userId,
      flashcardId: cardId,
      isRemembered: newRemembered,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.generatedSet.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final activeCards = _onlyUnremembered
        ? _cards.where((c) => !c.isRemembered).toList()
        : _cards;

    final rememberedCount = _cards.where((c) => c.isRemembered).length;
    final progress = _cards.isNotEmpty ? rememberedCount / _cards.length : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.generatedSet.title),
        actions: [
          IconButton(
            tooltip: _onlyUnremembered ? 'Hiện tất cả' : 'Chỉ hiện thẻ chưa nhớ',
            icon: Icon(
              _onlyUnremembered ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _onlyUnremembered ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _onlyUnremembered = !_onlyUnremembered;
                _currentIndex = 0;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar (PRA-01)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã thuộc $rememberedCount/${_cards.length} thẻ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: Colors.green,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),

              const SizedBox(height: 20),

              // Card Viewer
              if (activeCards.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.celebration_outlined, size: 64, color: Colors.green),
                        const SizedBox(height: 12),
                        const Text(
                          'Chúc mừng! Bạn đã thuộc hết các thẻ trong bộ này.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => setState(() => _onlyUnremembered = false),
                          child: const Text('Ôn tập lại từ đầu'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  'Thẻ ${_currentIndex + 1}/${activeCards.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FlashcardCard(
                    key: ValueKey(activeCards[_currentIndex].flashcard.id),
                    flashcard: activeCards[_currentIndex].flashcard,
                    isRemembered: activeCards[_currentIndex].isRemembered,
                    onToggleRemembered: () =>
                        _toggleRemembered(activeCards[_currentIndex]),
                  ),
                ),
                const SizedBox(height: 16),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Trước'),
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: activeCards[_currentIndex].isRemembered
                            ? Colors.orange.shade700
                            : Colors.green,
                      ),
                      icon: Icon(activeCards[_currentIndex].isRemembered
                          ? Icons.refresh
                          : Icons.check),
                      label: Text(activeCards[_currentIndex].isRemembered
                          ? 'Cần ôn lại'
                          : 'Đã nhớ thẻ'),
                      onPressed: () =>
                          _toggleRemembered(activeCards[_currentIndex]),
                    ),
                    OutlinedButton.icon(
                      label: const Text('Sau'),
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentIndex < activeCards.length - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
