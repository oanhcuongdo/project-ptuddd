import 'dart:convert';

import '../../../core/constants/app_config.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/nutrition_levels.dart';
import '../../../domain/enums.dart';

/// Một món AI trả về (chưa gắn nội dung gợi ý) + các mã gợi ý AI chọn.
class ParsedFoodItem {
  const ParsedFoodItem({required this.item, required this.tipCodes});

  final FoodItem item;
  final List<String> tipCodes;
}

class ParsedMealResponse {
  const ParsedMealResponse({required this.recognized, required this.items});

  final bool recognized;
  final List<ParsedFoodItem> items;

  /// Không nhận ra món nào -> chuyển sang nhập thủ công.
  bool get hasNoFood => !recognized || items.isEmpty;
}

/// Đọc + kiểm tra JSON của Gemini cho quét món / nhập tên món (Dart thuần).
///
/// Dù đã có responseSchema, app vẫn kiểm tra lại:
/// - chuỗi không phải JSON / không phải object -> ném [FormatException];
/// - thiếu tên món -> bỏ món đó;
/// - giá trị enum lạ hoặc thiếu -> dùng giá trị mặc định và hạ confidence = low
///   để người dùng kiểm tra lại;
/// - cắt short_note, tối đa 5 món, tối đa 3 mã gợi ý/món.
class MealResponseParser {
  MealResponseParser._();

  static ParsedMealResponse parse(String raw) {
    final decoded = jsonDecode(stripCodeFence(raw));
    if (decoded is! Map) {
      throw const FormatException('AI response is not a JSON object');
    }
    final recognized = decoded['recognized'] == true;
    final rawItems = decoded['items'] is List ? decoded['items'] as List : const [];
    final items = recognized
        ? rawItems
            .whereType<Map>()
            .map(_parseItem)
            .whereType<ParsedFoodItem>()
            .take(AppConfig.maxItemsPerScan)
            .toList()
        : <ParsedFoodItem>[];
    return ParsedMealResponse(recognized: recognized, items: items);
  }

  /// Bỏ ```json ... ``` nếu model lỡ bọc kết quả trong code fence.
  static String stripCodeFence(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
      if (text.endsWith('```')) text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  static ParsedFoodItem? _parseItem(Map m) {
    final rawName = m['name'];
    final name = rawName is String ? rawName.trim() : '';
    if (name.isEmpty) return null;

    var uncertain = false;
    final category = tryParseWire(FoodCategory.values, m['category']);
    if (category == null) uncertain = true;

    Level level(LevelAttribute attribute) {
      final value = tryParseWire(Level.values, m[attribute.conditionKey]);
      if (value == null) uncertain = true;
      return value ?? Level.medium;
    }

    final levels = NutritionLevels(
      sugar: level(LevelAttribute.sugar),
      fat: level(LevelAttribute.fat),
      carb: level(LevelAttribute.carb),
      veg: level(LevelAttribute.veg),
      protein: level(LevelAttribute.protein),
      energy: level(LevelAttribute.energy),
    );

    final confidence = tryParseWire(Confidence.values, m['confidence']) ?? Confidence.low;
    final rawNote = m['short_note'] is String ? (m['short_note'] as String).trim() : '';
    final note = rawNote.length > AppConfig.shortNoteMaxLength
        ? rawNote.substring(0, AppConfig.shortNoteMaxLength)
        : rawNote;
    final codes = (m['tip_codes'] is List ? m['tip_codes'] as List : const [])
        .whereType<String>()
        .toSet()
        .take(AppConfig.maxTipsPerItem)
        .toList();

    return ParsedFoodItem(
      item: FoodItem(
        name: name.length > 80 ? name.substring(0, 80) : name,
        category: category ?? FoodCategory.mainDish,
        levels: levels,
        shortNote: note,
        confidence: uncertain ? Confidence.low : confidence,
      ),
      tipCodes: codes,
    );
  }
}
