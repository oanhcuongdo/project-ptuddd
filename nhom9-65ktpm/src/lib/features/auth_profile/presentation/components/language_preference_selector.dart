import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class _LangChipData {
  final String code;
  final String badge;
  final String shortName;

  const _LangChipData(this.code, this.badge, this.shortName);
}

/// Component chọn Ngôn ngữ mẹ đẻ, Ngôn ngữ muốn luyện & Trình độ (A1–B2)
/// Giao diện pill chọn ngang chuẩn theo bản mẫu Thiết lập hồ sơ.
class LanguagePreferenceSelector extends StatelessWidget {
  static const List<_LangChipData> _langs = [
    _LangChipData('vi', 'VN', 'Việt'),
    _LangChipData('en', 'GB', 'Anh'),
    _LangChipData('zh', 'CN', 'Trung'),
  ];

  final String nativeLang;
  final String targetLang;
  final String proficiencyLevel;
  final ValueChanged<String> onNativeLangChanged;
  final ValueChanged<String> onTargetLangChanged;
  final ValueChanged<String> onLevelChanged;

  const LanguagePreferenceSelector({
    super.key,
    required this.nativeLang,
    required this.targetLang,
    required this.proficiencyLevel,
    required this.onNativeLangChanged,
    required this.onTargetLangChanged,
    required this.onLevelChanged,
  });

  String _shortNameOf(String code) {
    return _langs
        .firstWhere((e) => e.code == code, orElse: () => _langs.first)
        .shortName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Text(
              'Ngôn ngữ mẹ đẻ',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '(Bạn có thể hỗ trợ)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildLangRow(
          selectedCode: nativeLang,
          onSelect: onNativeLangChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Ngôn ngữ muốn luyện',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_shortNameOf(nativeLang)} ⇄ ${_shortNameOf(targetLang)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildLangRow(
                selectedCode: targetLang,
                onSelect: onTargetLangChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Trình độ hiện tại (Gợi ý kịch bản phù hợp)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: AppConstants.proficiencyLevels
                    .asMap()
                    .entries
                    .map((entry) {
                  final idx = entry.key;
                  final level = entry.value;
                  final isSelected = level == proficiencyLevel;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: idx < 3 ? 8 : 0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onLevelChanged(level),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEEF2FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                level,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLangRow({
    required String selectedCode,
    required ValueChanged<String> onSelect,
  }) {
    return Row(
      children: _langs.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final isSelected = item.code == selectedCode;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(item.code),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        '${item.badge} ${item.shortName}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
