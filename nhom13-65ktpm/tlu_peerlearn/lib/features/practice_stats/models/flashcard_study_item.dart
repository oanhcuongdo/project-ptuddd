import '../../ai_generator/models/flashcard_item.dart';

class FlashcardStudyItem {
  final FlashcardItem flashcard;
  final bool isRemembered;

  const FlashcardStudyItem({
    required this.flashcard,
    this.isRemembered = false,
  });

  FlashcardStudyItem copyWith({
    FlashcardItem? flashcard,
    bool? isRemembered,
  }) {
    return FlashcardStudyItem(
      flashcard: flashcard ?? this.flashcard,
      isRemembered: isRemembered ?? this.isRemembered,
    );
  }
}
