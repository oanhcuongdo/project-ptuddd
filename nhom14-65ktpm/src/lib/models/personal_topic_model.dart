class FieldItem {
  final String id;
  final String name;

  FieldItem({required this.id, required this.name});

  factory FieldItem.fromJson(Map<String, dynamic> json) {
    return FieldItem(
      id: json['id'].toString(),
      name: json['name'] ?? json['title'] ?? 'Chưa đặt tên',
    );
  }
}

class PersonalTopic {
  final String? id;
  final String userId;
  final String? fieldId;
  final String? fieldName; // Dùng để hiển thị tên lĩnh vực khi join bảng fields
  final String title;
  final String? description;
  final String? objectives;
  final String? technologies;
  final String? implementationPlan;
  final String status; // 'idea', 'in_progress', 'completed'
  final String source; // 'manual', 'ai_suggestion'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonalTopic({
    this.id,
    required this.userId,
    this.fieldId,
    this.fieldName,
    required this.title,
    this.description,
    this.objectives,
    this.technologies,
    this.implementationPlan,
    this.status = 'idea',
    this.source = 'manual',
    this.createdAt,
    this.updatedAt,
  });

  factory PersonalTopic.fromJson(Map<String, dynamic> json) {
    String? extractedFieldName;
    if (json['fields'] != null && json['fields'] is Map) {
      extractedFieldName = json['fields']['name'] ?? json['fields']['title'];
    }

    return PersonalTopic(
      id: json['id']?.toString(),
      userId: json['user_id'].toString(),
      fieldId: json['field_id']?.toString(),
      fieldName: extractedFieldName,
      title: json['title'] ?? '',
      description: json['description'],
      objectives: json['objectives'],
      technologies: json['technologies'],
      implementationPlan: json['implementation_plan'],
      status: json['status'] ?? 'idea',
      source: json['source'] ?? 'manual',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'field_id': fieldId,
      'title': title,
      'description': description,
      'objectives': objectives,
      'technologies': technologies,
      'implementation_plan': implementationPlan,
      'status': status,
      'source': source,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Hàm tiện ích chuyển mã status tiếng Anh sang nhãn tiếng Việt hiển thị trên UI
  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'Đang phát triển';
      case 'completed':
        return 'Hoàn thành';
      case 'idea':
      default:
        return 'Ý tưởng';
    }
  }
}
