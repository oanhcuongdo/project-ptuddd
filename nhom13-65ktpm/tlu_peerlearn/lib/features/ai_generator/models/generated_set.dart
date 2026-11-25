class GeneratedSet {
  final String id;
  final String roomId;
  final String createdBy;
  final String title;
  final String contentType; // 'flashcard' | 'quiz'
  final String difficulty; // 'basic' | 'medium' | 'advanced'
  final String? topic;
  final String status; // 'draft' | 'published' (BR-06)
  final int version; // (BR-07)
  final DateTime createdAt;
  final DateTime? publishedAt;

  const GeneratedSet({
    required this.id,
    required this.roomId,
    required this.createdBy,
    required this.title,
    required this.contentType,
    required this.difficulty,
    this.topic,
    this.status = 'draft',
    this.version = 1,
    required this.createdAt,
    this.publishedAt,
  });

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isFlashcard => contentType == 'flashcard';
  bool get isQuiz => contentType == 'quiz';

  factory GeneratedSet.fromJson(Map<String, dynamic> json) {
    return GeneratedSet(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      contentType: json['content_type'] as String,
      difficulty: json['difficulty'] as String,
      topic: json['topic'] as String?,
      status: json['status'] as String? ?? 'draft',
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'created_by': createdBy,
      'title': title,
      'content_type': contentType,
      'difficulty': difficulty,
      'topic': topic,
      'status': status,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  GeneratedSet copyWith({
    String? status,
    DateTime? publishedAt,
    int? version,
  }) {
    return GeneratedSet(
      id: id,
      roomId: roomId,
      createdBy: createdBy,
      title: title,
      contentType: contentType,
      difficulty: difficulty,
      topic: topic,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
