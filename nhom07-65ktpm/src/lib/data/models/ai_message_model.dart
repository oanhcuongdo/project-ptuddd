class AIMessageModel {
  final int? id;
  final String text;
  final bool isUser;
  final bool isOffline;
  final DateTime timestamp;

  AIMessageModel({
    this.id,
    required this.text,
    required this.isUser,
    this.isOffline = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'is_offline': isOffline ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AIMessageModel.fromMap(Map<String, dynamic> map) {
    return AIMessageModel(
      id: map['id'] as int?,
      text: map['text'] ?? '',
      isUser: (map['is_user'] as int? ?? 0) == 1,
      isOffline: (map['is_offline'] as int? ?? 0) == 1,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
