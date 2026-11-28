import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes/auth_routes.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/theme/app_spacing.dart';
import '../components/profile_header.dart';
import '../providers/auth_provider.dart';

/// Tab Hồ sơ — lắp ghép từ ProfileHeader + AppButton
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentProfile;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileHeader(profile: profile),
            const SizedBox(height: AppSpacing.xl),
            if (profile == null)
              AppButton(
                label: 'Đăng nhập / Đăng ký',
                icon: Icons.login,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AuthRoutes.login),
              )
            else
              OutlinedButton.icon(
                onPressed: auth.signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
          ],
        ),
      ),
    );
  }
}
