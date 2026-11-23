import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/language_model.dart';

/// Component chọn Ngôn ngữ muốn luyện tập & Trình độ hiện tại (A1–B2) kiểu Duolingo.
/// Danh sách ngôn ngữ được tải động từ bảng `languages` (Admin cấp phép) trên Supabase.
class LanguagePreferenceSelector extends StatelessWidget {
  final List<LanguageModel> languages;
  final bool isLoadingLanguages;
  final String? loadError;
  final VoidCallback? onRetryLoad;
  final String? targetLang;
  final String? proficiencyLevel;
  final ValueChanged<String> onTargetLangChanged;
  final ValueChanged<String> onLevelChanged;

  const LanguagePreferenceSelector({
    super.key,
    required this.languages,
    this.isLoadingLanguages = false,
    this.loadError,
    this.onRetryLoad,
    required this.targetLang,
    required this.proficiencyLevel,
    required this.onTargetLangChanged,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingLanguages) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Đang tải danh sách ngôn ngữ từ hệ thống...',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (loadError != null || languages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loadError ??
                  'Chưa có ngôn ngữ nào được kích hoạt trong bảng languages trên Supabase.',
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
            if (onRetryLoad != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: onRetryLoad,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tải lại danh sách ngôn ngữ'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn muốn luyện tập ngôn ngữ nào?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: languages.map((item) {
            final isSelected = item.code == targetLang;
            final label = item.flagCode.isNotEmpty
                ? '${item.flagCode} ${item.shortLabel}'
                : item.shortLabel;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTargetLangChanged(item.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEEF2FF)
                      : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 1.8 : 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const Text(
          'Trình độ hiện tại của bạn',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: AppConstants.proficiencyLevels.asMap().entries.map((entry) {
            final idx = entry.key;
            final level = entry.value;
            final isSelected = level == proficiencyLevel;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: idx < 3 ? 8 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onLevelChanged(level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEEF2FF)
                          : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.divider,
                        width: isSelected ? 1.8 : 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1),
                          offset: const Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          level,
                          style: TextStyle(
                            fontSize: 13.5,
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
    );
  }
}
