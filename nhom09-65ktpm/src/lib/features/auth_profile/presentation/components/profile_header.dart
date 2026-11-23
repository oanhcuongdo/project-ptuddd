import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/profile_model.dart';

/// Component hiển thị Avatar + Tên + Trình độ ngôn ngữ của người dùng
class ProfileHeader extends StatelessWidget {
  final ProfileModel? profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final subtitle = profile != null
        ? '${profile!.nativeLang.toUpperCase()} ⇄ ${profile!.targetLang.toUpperCase()} • ${profile!.proficiencyLevel}'
        : '${AppConstants.groupName} - Lớp ${AppConstants.classCode}';

    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          child: Icon(Icons.person, size: 40),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile?.displayName ?? 'Khách (Chưa đăng nhập)',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.muted),
      ],
    );
  }
}
