import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/data/models/language_model.dart';
import '../styles/chat_styles.dart';

/// Khung bộ lọc tinh gọn 2 hàng cho danh sách phòng học:
/// - Hàng 1: Ô tìm kiếm (tên phòng, người quản lý, mô tả) + Lọc Trình độ + Bật "Chỉ phòng còn chỗ"
/// - Hàng 2: Chip Ngôn ngữ bấm nhanh (tải động từ bảng `languages`)
class ChatFilterPanel extends StatelessWidget {
  static const String noLevelFilterValue = '__no_level__';

  final TextEditingController searchController;
  final List<LanguageModel> languages;
  final String? selectedLang;
  final String? selectedLevel;
  final bool onlyAvailable;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onLangSelected;
  final ValueChanged<String?> onLevelSelected;
  final ValueChanged<bool> onOnlyAvailableChanged;

  const ChatFilterPanel({
    super.key,
    required this.searchController,
    required this.languages,
    required this.selectedLang,
    required this.selectedLevel,
    required this.onlyAvailable,
    required this.onSearchChanged,
    required this.onLangSelected,
    required this.onLevelSelected,
    required this.onOnlyAvailableChanged,
  });

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Tìm theo tên phòng, người quản lý hoặc mô tả...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );

    final levelDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ChatStyles.controlBoxDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedLevel,
          isDense: true,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tất cả trình độ'),
            ),
            const DropdownMenuItem<String?>(
              value: noLevelFilterValue,
              child: Text('Mọi trình độ'),
            ),
            ...AppConstants.proficiencyLevels.map(
              (lvl) => DropdownMenuItem<String?>(
                value: lvl,
                child: Text('Yêu cầu $lvl'),
              ),
            ),
          ],
          onChanged: onLevelSelected,
        ),
      ),
    );

    final availableToggle = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onOnlyAvailableChanged(!onlyAvailable),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: onlyAvailable
              ? const Color(0xFFEEF2FF)
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onlyAvailable ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              onlyAvailable
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 17,
              color: onlyAvailable ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Chỉ phòng còn chỗ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onlyAvailable
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ChatStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 720) {
                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: AppSpacing.md),
                    levelDropdown,
                    const SizedBox(width: AppSpacing.sm),
                    availableToggle,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchField,
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [levelDropdown, availableToggle],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Ngôn ngữ:', style: ChatStyles.metaText),
              _LangChip(
                label: 'Tất cả',
                isActive: selectedLang == null,
                onTap: () => onLangSelected(null),
              ),
              ...languages.map(
                (lang) => _LangChip(
                  label: lang.shortLabel,
                  isActive: selectedLang == lang.code,
                  onTap: () => onLangSelected(lang.code),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
