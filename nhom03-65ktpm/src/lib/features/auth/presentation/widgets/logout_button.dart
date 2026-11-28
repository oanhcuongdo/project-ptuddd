import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../bloc/auth_cubit.dart';

/// Nút đăng xuất đặt trên AppBar; hỏi xác nhận trước khi đăng xuất.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AuthCubit>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Đăng xuất?',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng SmartNote.',
      confirmLabel: 'Đăng xuất',
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }
    await cubit.signOut();
    messenger.showSnackBar(const SnackBar(content: Text('Đã đăng xuất.')));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Đăng xuất',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => _confirmAndSignOut(context),
    );
  }
}
