import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/nutrition_levels.dart';
import '../../domain/enums.dart';

/// Hàm chuyển đổi dùng chung giữa Firestore và entity của Domain.
class FirestoreConverters {
  FirestoreConverters._();

  /// Luôn lưu thời gian dạng Timestamp UTC.
  static Timestamp toTimestamp(DateTime value) => Timestamp.fromDate(value.toUtc());

  /// Đọc Timestamp (hoặc null khi serverTimestamp chưa được server xác nhận).
  static DateTime? toDateTime(Object? raw) {
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is DateTime) return raw.toUtc();
    return null;
  }

  static int toInt(Object? raw, [int fallback = 0]) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return fallback;
  }

  static List<String> toStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  static Map<String, String> levelsToMap(NutritionLevels levels) => {
        for (final attribute in LevelAttribute.values)
          attribute.itemKey: levels.of(attribute).value,
      };

  static NutritionLevels levelsFromMap(Object? raw) {
    final map = raw is Map ? raw : const {};
    Level read(LevelAttribute a) => parseWire(Level.values, map[a.itemKey], Level.medium);
    return NutritionLevels(
      sugar: read(LevelAttribute.sugar),
      fat: read(LevelAttribute.fat),
      carb: read(LevelAttribute.carb),
      veg: read(LevelAttribute.veg),
      protein: read(LevelAttribute.protein),
      energy: read(LevelAttribute.energy),
    );
  }

  /// Ghi Firestore theo kiểu "không chờ server".
  ///
  /// Khi mất mạng, Future của set/update chỉ hoàn thành lúc có mạng lại.
  /// Firestore đã ghi ngay vào cache cục bộ và stream cập nhật tức thì,
  /// nên UI không cần `await`. Lỗi (ví dụ bị Security Rules từ chối) chỉ log.
  static void fireAndForget(Future<void> write, String label) {
    write.catchError((Object e) {
      debugPrint('Firestore write "$label" failed: $e');
    });
  }
}
