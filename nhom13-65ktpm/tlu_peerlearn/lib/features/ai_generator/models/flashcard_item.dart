class FlashcardItem {
  final String id;
  final String setId;
  final String frontText;
  final String backText;
  final String? explanation;
  final String? topic;
  final String? difficulty;

  const FlashcardItem({
    required this.id,
    required this.setId,
    required this.frontText,
    required this.backText,
    this.explanation,
    this.topic,
    this.difficulty,
  });

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      id: json['id'] as String? ?? '',
      setId: json['set_id'] as String? ?? '',
      frontText: json['front_text'] as String,
      backText: json['back_text'] as String,
      explanation: json['explanation'] as String?,
      topic: json['topic'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'set_id': setId,
      'front_text': frontText,
      'back_text': backText,
      'explanation': explanation,
      'topic': topic,
      'difficulty': difficulty,
    };
  }

  FlashcardItem copyWith({
    String? frontText,
    String? backText,
    String? explanation,
  }) {
    return FlashcardItem(
      id: id,
      setId: setId,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      explanation: explanation ?? this.explanation,
      topic: topic,
      difficulty: difficulty,
    );
  }
}
