class DrillItem {
  final String id;
  final String title;
  final String category;
  final int durationSeconds;
  final int restSeconds;
  final int sets;
  final String description;
  final String iconName;

  const DrillItem({
    required this.id,
    required this.title,
    required this.category,
    required this.durationSeconds,
    this.restSeconds = 60,
    this.sets = 1,
    this.description = '',
    this.iconName = 'sports_soccer',
  });

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedRestDuration {
    final minutes = (restSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (restSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get durationMinutes => (durationSeconds / 60).ceil();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'duration_seconds': durationSeconds,
      'rest_seconds': restSeconds,
      'sets': sets,
      'description': description,
      'icon_name': iconName,
    };
  }

  factory DrillItem.fromJson(Map<String, dynamic> json) {
    return DrillItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'Kỹ thuật',
      durationSeconds: json['duration_seconds'] as int? ?? 300,
      restSeconds: json['rest_seconds'] as int? ?? 60,
      sets: json['sets'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'sports_soccer',
    );
  }

  DrillItem copyWith({
    String? id,
    String? title,
    String? category,
    int? durationSeconds,
    int? restSeconds,
    int? sets,
    String? description,
    String? iconName,
  }) {
    return DrillItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
    );
  }
}
