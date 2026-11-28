import 'package:flutter/material.dart';

/// Loại lịch nhắc nhở
enum ReminderCategory {
  training('Tập luyện sân cỏ', Icons.sports_soccer, Color(0xFF10B981)),
  fitness('Thể lực & Gym', Icons.fitness_center, Color(0xFF3B82F6)),
  stretching('Giãn cơ & Phục hồi', Icons.self_improvement, Color(0xFF8B5CF6)),
  hydration('Bổ sung nước & Dinh dưỡng', Icons.water_drop, Color(0xFF06B6D4)),
  match('Lịch thi đấu trận bóng', Icons.emoji_events, Color(0xFFF59E0B));

  final String label;
  final IconData icon;
  final Color color;
  const ReminderCategory(this.label, this.icon, this.color);

  static ReminderCategory fromString(String value) {
    return ReminderCategory.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ReminderCategory.training,
    );
  }
}

/// Mô hình quản lý Lịch nhắc nhở ra sân & rèn luyện
/// Tác giả: Nguyễn Hồng Thái (Phân hệ 5 - Thống kê & Nhắc lịch ra sân)
class TrainingReminder {
  final String id;
  final String title;
  final ReminderCategory category;
  final int hour; // 0 - 23
  final int minute; // 0 - 59
  final List<int> repeatDays; // 1 = T2, 2 = T3, 3 = T4, 4 = T5, 5 = T6, 6 = T7, 7 = CN
  final bool isEnabled;
  final String note;

  const TrainingReminder({
    required this.id,
    required this.title,
    required this.category,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    this.isEnabled = true,
    this.note = '',
  });

  /// Chuỗi hiển thị giờ dạng HH:mm (VD: 17:30)
  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Chuỗi hiển thị các ngày lặp lại (VD: "T2, T4, T6" hoặc "Hàng ngày")
  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'Một lần';
    if (repeatDays.length == 7) return 'Hàng ngày';
    final map = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    final sorted = List<int>.from(repeatDays)..sort();
    return sorted.map((d) => map[d] ?? '').join(', ');
  }

  TrainingReminder copyWith({
    String? id,
    String? title,
    ReminderCategory? category,
    int? hour,
    int? minute,
    List<int>? repeatDays,
    bool? isEnabled,
    String? note,
  }) {
    return TrainingReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'hour': hour,
      'minute': minute,
      'repeat_days': repeatDays,
      'is_enabled': isEnabled,
      'note': note,
    };
  }

  factory TrainingReminder.fromJson(Map<String, dynamic> json) {
    return TrainingReminder(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? 'Nhắc lịch tập bóng đá',
      category: ReminderCategory.fromString(json['category'] as String? ?? ''),
      hour: json['hour'] as int? ?? 17,
      minute: json['minute'] as int? ?? 30,
      repeatDays: (json['repeat_days'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1, 3, 5],
      isEnabled: json['is_enabled'] as bool? ?? true,
      note: json['note'] as String? ?? '',
    );
  }
}
