import 'package:firebase_ai/firebase_ai.dart';

import '../../core/constants/app_config.dart';
import '../../domain/enums.dart';

/// JSON schema (structured output) cho Gemini.
///
/// Các trường mức độ, loại món, độ tin cậy và mã gợi ý đều là ENUM, nên
/// Gemini chỉ có thể trả về giá trị nằm trong danh sách cho phép.
/// Danh sách mã gợi ý [tipCodes] được truyền vào ĐỘNG từ thư viện tips.
class AiSchemas {
  AiSchemas._();

  static Schema _level(String description) =>
      Schema.enumString(enumValues: Level.wireValues, description: description);

  /// Mảng mã gợi ý. Nếu thư viện rỗng (chưa nạp tips) thì dùng string thường;
  /// app sẽ lọc bỏ mã lạ sau khi nhận kết quả.
  static Schema _tipCodes(List<String> tipCodes, {int? minItems, required int maxItems}) {
    return Schema.array(
      items: tipCodes.isEmpty
          ? Schema.string()
          : Schema.enumString(enumValues: tipCodes),
      minItems: minItems,
      maxItems: maxItems,
    );
  }

  /// Schema cho quét món (ảnh) và nhập tên món (văn bản).
  ///
  /// ```
  /// { recognized: bool,
  ///   items: [0..5] { name, category, sugar_level, fat_level, carb_level,
  ///                   veg_level, protein_level, energy_level,
  ///                   tip_codes[0..3], short_note, confidence } }
  /// ```
  static Schema mealAnalysis(List<String> tipCodes) {
    final item = Schema.object(
      properties: {
        'name': Schema.string(description: 'Tên món bằng tiếng Việt'),
        'category': Schema.enumString(enumValues: FoodCategory.wireValues),
        'sugar_level': _level('Độ ngọt'),
        'fat_level': _level('Dầu mỡ'),
        'carb_level': _level('Tinh bột'),
        'veg_level': _level('Lượng rau'),
        'protein_level': _level('Lượng đạm'),
        'energy_level': _level('Mức năng lượng tổng thể'),
        'tip_codes': _tipCodes(tipCodes, maxItems: AppConfig.maxTipsPerItem),
        'short_note': Schema.string(
          description: 'Mô tả ngắn thành phần nhìn thấy, tối đa '
              '${AppConfig.shortNoteMaxLength} ký tự, không khuyên',
        ),
        'confidence': Schema.enumString(enumValues: ['high', 'low']),
      },
      propertyOrdering: [
        'name',
        'category',
        'sugar_level',
        'fat_level',
        'carb_level',
        'veg_level',
        'protein_level',
        'energy_level',
        'tip_codes',
        'short_note',
        'confidence',
      ],
    );

    return Schema.object(
      properties: {
        'recognized': Schema.boolean(description: 'Ảnh/tên có phải đồ ăn, đồ uống không'),
        'items': Schema.array(items: item, maxItems: AppConfig.maxItemsPerScan),
      },
      propertyOrdering: ['recognized', 'items'],
    );
  }

  /// Schema cho Gọi món thông minh (ảnh thực đơn).
  ///
  /// ```
  /// { is_menu: bool,
  ///   recommendations: [0..3] { menu_item_name, how_to_order, reason_tip_codes[1..2] } }
  /// ```
  static Schema menuAnalysis(List<String> tipCodes) {
    final recommendation = Schema.object(
      properties: {
        'menu_item_name': Schema.string(description: 'Đúng tên món trên thực đơn'),
        'how_to_order': Schema.string(
          description: 'Cách gọi món ngắn gọn, tối đa ${AppConfig.howToOrderMaxLength} ký tự',
        ),
        'reason_tip_codes': _tipCodes(tipCodes, minItems: 1, maxItems: 2),
      },
      propertyOrdering: ['menu_item_name', 'how_to_order', 'reason_tip_codes'],
    );

    return Schema.object(
      properties: {
        'is_menu': Schema.boolean(description: 'Ảnh có phải thực đơn không'),
        'recommendations': Schema.array(items: recommendation, maxItems: 3),
      },
      propertyOrdering: ['is_menu', 'recommendations'],
    );
  }
}
