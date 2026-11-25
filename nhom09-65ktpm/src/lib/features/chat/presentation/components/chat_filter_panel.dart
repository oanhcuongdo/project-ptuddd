import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/data/models/language_model.dart';
import '../styles/chat_styles.dart';

/// Thanh tìm kiếm & bộ lọc dạng Pill tông Xanh Ngọc theo bố cục hiện đại:
/// - Hàng 1: Ô tìm kiếm bo tròn + Lọc trình độ + Chỉ phòng còn chỗ
/// - Hàng 2: Chip ngôn ngữ bấm nhanh (tải động từ bảng `languages`)
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
        hintText: 'Tìm phòng học, người quản lý hoặc mô tả...',
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: ChatStyles.tealPrimary,
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
        filled: true,
        fillColor: const Color(0xFFF4F7F8),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFFE2ECEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(
            color: ChatStyles.tealPrimary,
            width: 1.5,
          ),
        ),
      ),
    );

    final levelDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE7EA)),
      ),
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
      borderRadius: BorderRadius.circular(999),
      onTap: () => onOnlyAvailableChanged(!onlyAvailable),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: onlyAvailable
              ? ChatStyles.tealSoftBg
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: onlyAvailable
                ? ChatStyles.tealPrimary
                : const Color(0xFFDCE7EA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              onlyAvailable
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: onlyAvailable
                  ? ChatStyles.tealPrimary
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Chỉ phòng còn chỗ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onlyAvailable
                    ? ChatStyles.tealDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
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
            _LangPill(
              icon: Icons.grid_view_rounded,
              label: 'Tất cả',
              isActive: selectedLang == null,
              onTap: () => onLangSelected(null),
            ),
            ...languages.map(
              (lang) => _LangPill(
                icon: Icons.translate_rounded,
                label: lang.shortLabel,
                isActive: selectedLang == lang.code,
                onTap: () => onLangSelected(lang.code),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LangPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangPill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ChatStyles.tealPrimary : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? ChatStyles.tealPrimary
                : const Color(0xFFDCE7EA),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ChatStyles.tealPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.5,
              color: isActive ? Colors.white : ChatStyles.tealDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
