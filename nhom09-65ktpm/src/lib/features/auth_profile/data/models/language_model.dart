/// Ánh xạ bảng `languages` — danh mục ngôn ngữ do Admin cấp phép trên Supabase.
class LanguageModel {
  final String code;
  final String name;
  final String shortLabel;
  final String flagCode;
  final bool isActive;
  final int sortOrder;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.shortLabel,
    required this.flagCode,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory LanguageModel.fromMap(Map<String, dynamic> map) {
    return LanguageModel(
      code: map['code'].toString(),
      name: map['name'] as String? ?? map['code'].toString(),
      shortLabel: map['short_label'] as String? ?? map['code'].toString(),
      flagCode: map['flag_code'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
