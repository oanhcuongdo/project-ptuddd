import 'dart:convert';

/// Một câu gợi ý mở đầu hội thoại song ngữ Anh - Việt.
class ConversationStarter {
  final String textEn;
  final String textVi;
  final String tip;

  const ConversationStarter({
    required this.textEn,
    required this.textVi,
    this.tip = '',
  });

  factory ConversationStarter.fromDynamic(dynamic raw) {
    if (raw is String) {
      return ConversationStarter(textEn: raw, textVi: '');
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return ConversationStarter(
        textEn: (map['text_en'] ?? map['en'] ?? map['text'] ?? '').toString(),
        textVi: (map['text_vi'] ?? map['vi'] ?? '').toString(),
        tip: (map['tip'] ?? '').toString(),
      );
    }
    return const ConversationStarter(textEn: '', textVi: '');
  }

  Map<String, dynamic> toMap() => {
        'text_en': textEn,
        'text_vi': textVi,
        'tip': tip,
      };
}

/// Một lượt thoại trong kịch bản mẫu giữa 2 nhân vật (A / B).
class SampleDialogueLine {
  final String speaker;
  final String role;
  final String textEn;
  final String textVi;

  const SampleDialogueLine({
    required this.speaker,
    required this.role,
    required this.textEn,
    required this.textVi,
  });

  factory SampleDialogueLine.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return SampleDialogueLine(
        speaker: (map['speaker'] ?? 'A').toString(),
        role: (map['role'] ?? '').toString(),
        textEn: (map['text_en'] ?? map['en'] ?? map['text'] ?? '').toString(),
        textVi: (map['text_vi'] ?? map['vi'] ?? '').toString(),
      );
    }
    return const SampleDialogueLine(
      speaker: 'A',
      role: '',
      textEn: '',
      textVi: '',
    );
  }

  Map<String, dynamic> toMap() => {
        'speaker': speaker,
        'role': role,
        'text_en': textEn,
        'text_vi': textVi,
      };
}

/// Ánh xạ bảng `conversation_topics` — Chủ đề & kịch bản hội thoại theo cấp độ A1-B2.
class TopicModel {
  static const List<String> supportedLevels = ['A1', 'A2', 'B1', 'B2'];

  final String id;
  final String title;
  final String titleEn;
  final String level;
  final String category;
  final String description;
  final String descriptionEn;
  final String thumbnailIcon;
  final int estimatedMinutes;
  final List<ConversationStarter> conversationStarters;
  final List<SampleDialogueLine> sampleDialogues;
  final bool isCompleted;
  final DateTime createdAt;

  const TopicModel({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.level,
    required this.category,
    this.description = '',
    this.descriptionEn = '',
    this.thumbnailIcon = '💬',
    this.estimatedMinutes = 15,
    this.conversationStarters = const [],
    this.sampleDialogues = const [],
    this.isCompleted = false,
    required this.createdAt,
  });

  TopicModel copyWith({
    String? title,
    String? titleEn,
    String? level,
    String? category,
    String? description,
    String? descriptionEn,
    String? thumbnailIcon,
    int? estimatedMinutes,
    List<ConversationStarter>? conversationStarters,
    List<SampleDialogueLine>? sampleDialogues,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TopicModel(
      id: id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      level: level ?? this.level,
      category: category ?? this.category,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      thumbnailIcon: thumbnailIcon ?? this.thumbnailIcon,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      conversationStarters: conversationStarters ?? this.conversationStarters,
      sampleDialogues: sampleDialogues ?? this.sampleDialogues,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TopicModel.fromMap(
    Map<String, dynamic> map, {
    bool isCompleted = false,
  }) {
    final startersRaw = _decodeJsonList(map['conversation_starters']);
    final dialoguesRaw = _decodeJsonList(map['sample_dialogues']);

    return TopicModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      titleEn: (map['title_en'] ?? '').toString(),
      level: (map['level'] ?? 'A1').toString().toUpperCase(),
      category: (map['category'] ?? 'Daily Life').toString(),
      description: (map['description'] ?? '').toString(),
      descriptionEn: (map['description_en'] ?? '').toString(),
      thumbnailIcon: (map['thumbnail_icon'] ?? '💬').toString(),
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt() ?? 15,
      conversationStarters: startersRaw
          .map(ConversationStarter.fromDynamic)
          .where((item) => item.textEn.isNotEmpty)
          .toList(),
      sampleDialogues: dialoguesRaw
          .map(SampleDialogueLine.fromDynamic)
          .where((item) => item.textEn.isNotEmpty)
          .toList(),
      isCompleted: isCompleted,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'title_en': titleEn,
        'level': level,
        'category': category,
        'description': description,
        'description_en': descriptionEn,
        'thumbnail_icon': thumbnailIcon,
        'estimated_minutes': estimatedMinutes,
        'conversation_starters':
            conversationStarters.map((item) => item.toMap()).toList(),
        'sample_dialogues':
            sampleDialogues.map((item) => item.toMap()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  static List<dynamic> _decodeJsonList(dynamic value) {
    if (value is List) return value;
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }
}

