enum HabitCategory {
  technical, // Kỹ thuật bóng đá
  fitness,   // Thể lực
  nutrition, // Dinh dưỡng
}

enum HabitType {
  quantitative, // Định lượng (số lần, km, lít nước, phút)
  qualitative,  // Định tính (đã làm / chưa làm: check-in)
}

class HabitModel {
  final String id;
  String title;
  String description;
  HabitCategory category;
  HabitType type;
  
  // Dành cho định lượng (vd: targetValue = 500, unit = "lần" / targetValue = 3.0, unit = "lít")
  double targetValue;
  double currentValue;
  String unit;

  // Trạng thái hoàn thành hôm nay
  bool isCompletedToday;

  HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    this.targetValue = 1,
    this.currentValue = 0,
    this.unit = '',
    this.isCompletedToday = false,
  });

  HabitModel copyWith({
    String? id,
    String? title,
    String? description,
    HabitCategory? category,
    HabitType? type,
    double? targetValue,
    double? currentValue,
    String? unit,
    bool? isCompletedToday,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }
}
