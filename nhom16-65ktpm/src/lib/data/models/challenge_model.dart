import 'dart:convert';
import 'package:intl/intl.dart';

/// Model cho bảng `challenges`
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final double rewardAmount;
  final String category; // vd: 'Học tập', 'Gia sư', 'Sức khỏe', 'Môi trường'
  final String icon;
  final bool isActive;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardAmount,
    required this.category,
    required this.icon,
    this.isActive = true,
  });

  /// Kiểm tra dữ liệu hợp lệ
  bool isValid() {
    return id.trim().isNotEmpty &&
        title.trim().isNotEmpty &&
        rewardAmount >= 0;
  }

  /// Định dạng số tiền thưởng dạng VND (vd: 20.000 đ)
  String get formattedRewardAmount {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(rewardAmount);
  }

  /// Chuyển đối tượng thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardAmount': rewardAmount,
      'category': category,
      'icon': icon,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Khởi tạo đối tượng từ Map lấy từ SQLite
  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      rewardAmount: (map['rewardAmount'] as num).toDouble(),
      category: map['category'] as String,
      icon: map['icon'] as String,
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }

  /// JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardAmount': rewardAmount,
      'category': category,
      'icon': icon,
      'isActive': isActive,
    };
  }

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      rewardAmount: (json['rewardAmount'] as num).toDouble(),
      category: json['category'] as String,
      icon: json['icon'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ChallengeModel.fromJsonString(String source) =>
      ChallengeModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    double? rewardAmount,
    String? category,
    String? icon,
    bool? isActive,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.rewardAmount == rewardAmount &&
        other.category == category &&
        other.icon == icon &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      rewardAmount,
      category,
      icon,
      isActive,
    );
  }
}
