import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AvatarPreset {
  final String id;
  final String emoji;
  final String label;
  final Color bgColor;

  const AvatarPreset({
    required this.id,
    required this.emoji,
    required this.label,
    required this.bgColor,
  });
}

/// Component chọn ảnh đại diện linh vật (hỗ trợ thêm tùy chọn giữ ảnh Google nếu có)
class AvatarPicker extends StatelessWidget {
  static const String googleAvatarId = 'google';

  static const List<AvatarPreset> presets = [
    AvatarPreset(
      id: 'owl',
      emoji: '🦉',
      label: 'Cú Thông Thái',
      bgColor: Color(0xFFEEF2FF),
    ),
    AvatarPreset(
      id: 'fox',
      emoji: '🦊',
      label: 'Cáo Nhanh Nhẹn',
      bgColor: Color(0xFFFFF3E0),
    ),
    AvatarPreset(
      id: 'panda',
      emoji: '🐼',
      label: 'Gấu Chăm Chỉ',
      bgColor: Color(0xFFE0F7FA),
    ),
    AvatarPreset(
      id: 'cat',
      emoji: '🐱',
      label: 'Mèo Tinh Nghịch',
      bgColor: Color(0xFFFCE4EC),
    ),
    AvatarPreset(
      id: 'astronaut',
      emoji: '🧑‍🚀',
      label: 'Phi Hành Gia',
      bgColor: Color(0xFFF3E8FF),
    ),
  ];

  final String selectedId;
  final String? googlePhotoUrl;
  final ValueChanged<String> onSelected;

  const AvatarPicker({
    super.key,
    required this.selectedId,
    this.googlePhotoUrl,
    required this.onSelected,
  });

  String get _currentLabel {
    if (selectedId == googleAvatarId) return 'Ảnh Google của bạn';
    return presets
        .firstWhere((p) => p.id == selectedId, orElse: () => presets.first)
        .label;
  }

  @override
  Widget build(BuildContext context) {
    final hasGooglePhoto =
        googlePhotoUrl != null && googlePhotoUrl!.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Chọn ảnh đại diện',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _currentLabel,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (hasGooglePhoto)
              _AvatarCircle(
                isSelected: selectedId == googleAvatarId,
                bgColor: const Color(0xFFEEF2FF),
                onTap: () => onSelected(googleAvatarId),
                child: ClipOval(
                  child: Image.network(
                    googlePhotoUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: AppColors.primary),
                  ),
                ),
              ),
            ...presets.map(
              (item) => _AvatarCircle(
                isSelected: item.id == selectedId,
                bgColor: item.bgColor,
                onTap: () => onSelected(item.id),
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final bool isSelected;
  final Color bgColor;
  final Widget child;
  final VoidCallback onTap;

  const _AvatarCircle({
    required this.isSelected,
    required this.bgColor,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2.2,
                ),
              ),
              alignment: Alignment.center,
              child: child,
            ),
            if (isSelected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.8),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
