import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CashewAmountKeypad extends StatelessWidget {
  const CashewAmountKeypad({super.key, required this.onKeyPressed});

  final ValueChanged<String> onKeyPressed;

  static const _keys = <String>[
    '7',
    '8',
    '9',
    '⌫',
    '4',
    '5',
    '6',
    '−',
    '1',
    '2',
    '3',
    '+',
    '000',
    '0',
    'C',
    '=',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final keyValue = _keys[index];
        final isAction = keyValue == '⌫' || keyValue == 'C' || keyValue == '=';
        final isOperator = keyValue == '+' || keyValue == '−';
        return OutlinedButton(
          key: Key('cashew_key_$keyValue'),
          onPressed: () => onKeyPressed(keyValue),
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
        );
      },
    );
  }
}
