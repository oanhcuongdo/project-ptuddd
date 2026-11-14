import 'package:flutter/foundation.dart';
import '../../domain/entities/soroban_column.dart';

class AbacusController extends ChangeNotifier {
  final int columnCount;
  late List<SorobanColumn> _columns;
  Function()? onBeadChanged;

  AbacusController({this.columnCount = 3, this.onBeadChanged}) {
    reset();
  }

  List<SorobanColumn> get columns => List.unmodifiable(_columns);

  /// Tổng giá trị số của toàn bộ bàn tính
  int get totalValue {
    int sum = 0;
    for (int i = 0; i < _columns.length; i++) {
      final power = _columns.length - 1 - i;
      int multiplier = 1;
      for (int p = 0; p < power; p++) {
        multiplier *= 10;
      }
      sum += _columns[i].value * multiplier;
    }
    return sum;
  }

  void reset() {
    _columns = List.generate(
      columnCount,
      (index) => SorobanColumn(columnIndex: index),
    );
    notifyListeners();
    onBeadChanged?.call();
  }

  void toggleUpperBead(int colIdx) {
    if (colIdx < 0 || colIdx >= _columns.length) return;
    final col = _columns[colIdx];
    _columns[colIdx] = col.copyWith(upperBeadActive: !col.upperBeadActive);
    notifyListeners();
    onBeadChanged?.call();
  }

  void setLowerBeads(int colIdx, int activeCount) {
    if (colIdx < 0 || colIdx >= _columns.length) return;
    final clamped = activeCount.clamp(0, 4);
    final col = _columns[colIdx];
    if (col.lowerBeadsActive == clamped) {
      // Nếu bấm vào số hạt hiện tại thì đẩy lùi về 0 (toggle)
      _columns[colIdx] = col.copyWith(lowerBeadsActive: 0);
    } else {
      _columns[colIdx] = col.copyWith(lowerBeadsActive: clamped);
    }
    notifyListeners();
    onBeadChanged?.call();
  }

  void setValue(int value) {
    int temp = value;
    final newCols = List<SorobanColumn>.filled(
      columnCount,
      const SorobanColumn(columnIndex: 0),
    );
    for (int i = columnCount - 1; i >= 0; i--) {
      final digit = temp % 10;
      newCols[i] = SorobanColumn.fromValue(i, digit);
      temp = temp ~/ 10;
    }
    _columns = newCols;
    notifyListeners();
    onBeadChanged?.call();
  }
}
