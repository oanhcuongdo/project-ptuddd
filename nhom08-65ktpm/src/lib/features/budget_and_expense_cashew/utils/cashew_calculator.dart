/// Evaluates quick arithmetic expressions for the Cashew-style amount keypad.
abstract final class CashewCalculator {
  /// Evaluates [expression] supporting `+`, `-`/`−`, `*`/`×`, `/`/`÷`.
  ///
  /// Returns `null` if [expression] is empty, syntactically invalid, or
  /// attempts division by zero.
  static double? evaluate(String expression) {
    final normalized = expression
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(RegExp(r'\s+'), '');

    if (normalized.isEmpty) return null;

    final tokens = _tokenize(normalized);
    if (tokens == null || tokens.isEmpty) return null;

    // First pass: * and /
    final values = <double>[];
    final ops = <String>[];

    final firstVal = double.tryParse(tokens.first);
    if (firstVal == null) return null;
    values.add(firstVal);

    var i = 1;
    while (i < tokens.length) {
      if (i + 1 >= tokens.length) return null;
      final op = tokens[i];
      final rhs = double.tryParse(tokens[i + 1]);
      if (rhs == null) return null;

      if (op == '*' || op == '/') {
        if (op == '/' && rhs == 0) return null;
        final lhs = values.removeLast();
        final combined = op == '*' ? lhs * rhs : lhs / rhs;
        if (!combined.isFinite) return null;
        values.add(combined);
      } else if (op == '+' || op == '-') {
        ops.add(op);
        values.add(rhs);
      } else {
        return null;
      }
      i += 2;
    }

    // Second pass: + and -
    var total = values.first;
    for (var j = 0; j < ops.length; j++) {
      final rhs = values[j + 1];
      total = ops[j] == '+' ? total + rhs : total - rhs;
    }
    return total.isFinite ? total : null;
  }

  /// Appends [operatorSymbol] (`+`, `-`, `*`, `/`) without duplicating trailing operators.
  static String appendOperator(String current, String operatorSymbol) {
    final trimmed = current.trimRight();
    if (trimmed.isEmpty) return '';
    final normalizedOp = operatorSymbol
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    if (RegExp(r'[+\-*/]$').hasMatch(trimmed)) {
      return '${trimmed.substring(0, trimmed.length - 1)}$normalizedOp ';
    }
    return '$trimmed $normalizedOp ';
  }

  static List<String>? _tokenize(String input) {
    final tokens = <String>[];
    var i = 0;
    while (i < input.length) {
      final ch = input[i];
      final isUnaryMinus = ch == '-' && (tokens.isEmpty || _isOperator(tokens.last));
      if (_isDigitOrDot(ch) || isUnaryMinus) {
        final buf = StringBuffer(ch);
        i++;
        while (i < input.length && _isDigitOrDot(input[i])) {
          buf.write(input[i]);
          i++;
        }
        tokens.add(buf.toString());
        continue;
      }
      if (_isOperator(ch)) {
        // Collapse repeated operators (e.g. `100 ++ 50` -> `100 + 50`) rather than crashing.
        if (tokens.isNotEmpty && _isOperator(tokens.last)) {
          tokens[tokens.length - 1] = ch;
        } else {
          tokens.add(ch);
        }
        i++;
        continue;
      }
      return null;
    }
    return tokens;
  }

  static bool _isOperator(String ch) =>
      ch == '+' || ch == '-' || ch == '*' || ch == '/';

  static bool _isDigitOrDot(String ch) =>
      (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || ch == '.';
}
