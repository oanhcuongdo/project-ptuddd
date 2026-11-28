import 'package:flutter/material.dart';

/// Vòng chờ nhỏ đặt trong nút hoặc dòng chữ.
///
/// Dùng thay `CircularProgressIndicator` tự cấu hình rải rác trong widget
/// (xem `docs/ui_ux.md` mục 2).
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({this.size = 20, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
