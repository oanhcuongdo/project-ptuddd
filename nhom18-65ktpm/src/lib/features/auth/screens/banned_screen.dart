import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/auth_backdrop.dart';
import '../../../repositories/auth_repository.dart';

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AuthBackdrop(
        heroFraction: 0.36,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.dangerBg,
                          border: Border.all(
                            color: AppColors.sosRed.withValues(alpha: 0.28),
                            width: 1.6,
                          ),
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          size: 40,
                          color: AppColors.sosRed,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tài khoản đã bị khóa',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tài khoản của bạn đã bị khóa do vi phạm chính sách. '
                        'Vui lòng liên hệ quản trị viên để được hỗ trợ.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                        ),
                        onPressed: () => AuthRepository().signOut(),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
