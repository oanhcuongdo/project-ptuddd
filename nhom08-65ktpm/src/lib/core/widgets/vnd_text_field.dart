import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// TextInputFormatter định dạng số tiền VNĐ có dấu chấm hàng nghìn theo thời gian thực.
class VndThousandInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final parsed = int.tryParse(digits);
    if (parsed == null) return oldValue;

    final formatted = formatDigits(digits);
    final digitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.extentOffset.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    var cursorOffset = 0;
    var seenDigits = 0;
    while (cursorOffset < formatted.length && seenDigits < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[cursorOffset])) {
        seenDigits++;
      }
      cursorOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  static String formatDigits(String rawDigits) {
    final clean = rawDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final buf = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(clean[i]);
    }
    return buf.toString();
  }
}

/// Ô nhập tiền VNĐ chuẩn dùng chung, tự động chèn dấu chấm ngăn cách hàng nghìn.
class VndTextField extends StatelessWidget {
  const VndTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText = '0',
    this.suffixText = 'đ',
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.border = const OutlineInputBorder(),
    this.style,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? labelText;
  final String hintText;
  final String? suffixText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextAlign textAlign;
  final InputBorder? border;
  final TextStyle? style;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      textAlign: textAlign,
      keyboardType: TextInputType.number,
      inputFormatters: [VndThousandInputFormatter()],
      style: style ?? AppTheme.monoAmount(fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixText: suffixText,
        border: border,
        isDense: true,
      ),
      onChanged: onChanged == null
          ? null
          : (value) => onChanged!(AppFormatters.parseVnd(value)),
    );
  }
}
