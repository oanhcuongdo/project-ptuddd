import 'package:flutter/material.dart';

/// Component nút Đăng nhập bằng Google riêng cho phân hệ Auth
class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const Icon(Icons.login),
      label: const Text('Đăng nhập bằng Google'),
    );
  }
}
