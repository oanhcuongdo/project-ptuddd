import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Component thanh đo độ mạnh mật khẩu 3 vạch (Yếu / Trung bình / Mạnh)
class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  int get _score {
    if (password.isEmpty) return 0;
    int points = 0;
    if (password.length >= 6) points++;
    if (password.length >= 8 &&
        RegExp(r'[A-Z0-9]').hasMatch(password)) {
      points++;
    }
    if (password.length >= 10 &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>0-9]').hasMatch(password)) {
      points++;
    }
    return points.clamp(1, 3);
  }

  Color get _activeColor {
    switch (_score) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.accent;
      case 3:
        return const Color(0xFF10B981);
      default:
        return AppColors.divider;
    }
  }

  String get _label {
    switch (_score) {
      case 1:
        return 'Yếu';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Mạnh';
      default:
        return 'Chưa nhập';
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final color = _activeColor;

    return Column(
      children: [
        Row(
          children: List.generate(3, (index) {
            final isFilled = index < score;
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isFilled ? color : AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Độ mạnh mật khẩu',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: score == 0 ? AppColors.textMuted : color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
