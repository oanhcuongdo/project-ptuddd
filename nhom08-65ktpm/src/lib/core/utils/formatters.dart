/// Shared formatting utilities for Vietnamese currency and dates.
abstract final class AppFormatters {
  static String formatVnd(num amount) {
    final rounded = amount.round();
    final absStr = rounded.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < absStr.length; i++) {
      if (i > 0 && (absStr.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(absStr[i]);
    }
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix${buf.toString()}đ';
  }

  static int parseVnd(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  /// Parses VND while preserving a leading `-` sign so negative inputs stay invalid.
  static int parseSignedVnd(String input) {
    final trimmed = input.trim();
    final isNegative = trimmed.startsWith('-');
    final value = parseVnd(trimmed);
    return isNegative ? -value : value;
  }

  static String formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  static String formatDateRange(DateTime start, DateTime end) {
    final sdd = start.day.toString().padLeft(2, '0');
    final smm = start.month.toString().padLeft(2, '0');
    return '$sdd/$smm – ${formatDate(end)}';
  }
}
