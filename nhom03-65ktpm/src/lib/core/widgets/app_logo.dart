import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Khối logo SmartNote — tham chiếu `15_brand_visual.png`: ô bo góc màu xanh
/// thương hiệu, icon bút + dòng ghi chú màu trắng.
///
/// [onPrimary] dùng khi đặt logo trên nền gradient thương hiệu: ô chuyển sang
/// trắng, icon giữ màu `primary` để vẫn tương phản.
class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 48, this.onPrimary = false, super.key});

  final double size;

  /// Biến thể đặt trên nền xanh đậm (hero đăng nhập, splash).
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = onPrimary ? scheme.onPrimary : scheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onPrimary ? scheme.onPrimary : null,
        gradient: onPrimary
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  base,
                  Color.lerp(base, scheme.onPrimary, 0.32)!,
                ],
              ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: onPrimary
            ? null
            : AppShadows.primary(scheme.primary).map((BoxShadow shadow) {
                return BoxShadow(
                  color: shadow.color.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                );
              }).toList(),
      ),
      child: Icon(
        Icons.edit_note_rounded,
        size: size * 0.58,
        color: onPrimary ? scheme.primary : scheme.onPrimary,
      ),
    );
  }
}
