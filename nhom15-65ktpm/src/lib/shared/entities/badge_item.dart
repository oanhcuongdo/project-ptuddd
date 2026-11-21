import 'package:equatable/equatable.dart';

class BadgeItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon; // Emoji hoặc đường dẫn asset
  final String category; // 'streak', 'accuracy', 'speed', 'voice', 'milestone'
  final String? unlockedAt; // null nếu chưa mở khóa

  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  BadgeItem copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    String? category,
    String? unlockedAt,
  }) {
    return BadgeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'unlockedAt': unlockedAt,
    };
  }

  factory BadgeItem.fromMap(Map<String, dynamic> map) {
    return BadgeItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '⭐',
      category: map['category'] ?? 'milestone',
      unlockedAt: map['unlockedAt'],
    );
  }

  @override
  List<Object?> get props => [id, title, description, icon, category, unlockedAt];
}

/// Danh mục huy hiệu chuẩn hệ thống Gamification
class BadgeDefinitions {
  static const List<BadgeItem> allBadges = [
    BadgeItem(
      id: 'starter_star',
      title: 'Bé Tập Sự',
      description: 'Hoàn thành bài tập Finger Math đầu tiên',
      icon: '⭐',
      category: 'milestone',
    ),
    BadgeItem(
      id: 'streak_3_days',
      title: 'Chiến Binh Chăm Chỉ',
      description: 'Học liên tục 3 ngày không bỏ lỡ',
      icon: '🔥',
      category: 'streak',
    ),
    BadgeItem(
      id: 'streak_7_days',
      title: 'Siêu Sao Bền Bỉ',
      description: 'Duy trì chuỗi học tập 7 ngày xuất sắc',
      icon: '🏆',
      category: 'streak',
    ),
    BadgeItem(
      id: 'streak_14_days',
      title: 'Huyền Thoại Kiên Trì',
      description: 'Học tập bền bỉ suốt 14 ngày liên tục',
      icon: '👑',
      category: 'streak',
    ),
    BadgeItem(
      id: 'accuracy_master',
      title: 'Bách Phát Bách Trúng',
      description: 'Đạt độ chính xác 100% trong 5 bài làm liên tiếp',
      icon: '🎯',
      category: 'accuracy',
    ),
    BadgeItem(
      id: 'speed_demon',
      title: 'Tia Chớp Finger Math',
      description: 'Trả lời đúng trong thời gian dưới 1.5 giây',
      icon: '⚡',
      category: 'speed',
    ),
    BadgeItem(
      id: 'voice_explorer',
      title: 'Nhà Du Hành Giọng Nói',
      description: 'Trả lời chính xác bằng giọng nói Micro AI',
      icon: '🎙️',
      category: 'voice',
    ),
  ];
}
