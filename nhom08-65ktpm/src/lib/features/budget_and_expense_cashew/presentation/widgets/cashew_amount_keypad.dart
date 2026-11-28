import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class CashewAmountKeypad extends StatelessWidget {
  const CashewAmountKeypad({super.key, required this.onKeyPressed});

  final ValueChanged<String> onKeyPressed;

  static const _keys = <String>[
    '7', '8', '9', '÷', '⌫',
    '4', '5', '6', '×', 'C',
    '1', '2', '3', '−', '+',
    '000', '0', '=',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          _keys.sublist(0, 5),
          _keys.sublist(5, 10),
          _keys.sublist(10, 15),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  Expanded(child: _buildKey(row[i])),
                  if (i < row.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        Row(
          children: [
            Expanded(flex: 2, child: _buildKey('000')),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: _buildKey('0')),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _buildKey('=')),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String keyValue) {
    final isAction = keyValue == '⌫' || keyValue == 'C' || keyValue == '=';
    final isOperator =
        keyValue == '+' || keyValue == '−' || keyValue == '×' || keyValue == '÷';
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        key: Key('cashew_key_$keyValue'),
        onPressed: () {
          HapticFeedback.lightImpact();
          onKeyPressed(keyValue);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: isAction || isOperator
              ? AppColors.onPrimaryContainer
              : AppColors.onSurface,
          backgroundColor: keyValue == '='
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          side: const BorderSide(color: AppColors.outlineVariantSoft),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: keyValue == '⌫'
            ? const Icon(Icons.backspace_outlined, size: 19)
            : Text(
                keyValue,
                style: TextStyle(
                  fontSize: keyValue == '000' ? 14 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
