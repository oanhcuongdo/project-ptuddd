import 'package:equatable/equatable.dart';

class SorobanColumn extends Equatable {
  final int columnIndex; // 0: Hàng trăm, 1: Hàng chục, 2: Hàng đơn vị (hoặc từ trái qua phải)
  final bool upperBeadActive; // Hạt trên chạm xà ngang = 5
  final int lowerBeadsActive; // Số hạt dưới chạm xà ngang (0..4)

  const SorobanColumn({
    required this.columnIndex,
    this.upperBeadActive = false,
    this.lowerBeadsActive = 0,
  });

  /// Giá trị số thực tế của cột (0 đến 9)
  int get value => (upperBeadActive ? 5 : 0) + lowerBeadsActive;

  SorobanColumn copyWith({
    int? columnIndex,
    bool? upperBeadActive,
    int? lowerBeadsActive,
  }) {
    return SorobanColumn(
      columnIndex: columnIndex ?? this.columnIndex,
      upperBeadActive: upperBeadActive ?? this.upperBeadActive,
      lowerBeadsActive: lowerBeadsActive ?? this.lowerBeadsActive,
    );
  }

  /// Thiết lập giá trị số cụ thể cho cột (0 đến 9)
  factory SorobanColumn.fromValue(int columnIndex, int value) {
    final clamped = value.clamp(0, 9);
    final upper = clamped >= 5;
    final lower = clamped % 5;
    return SorobanColumn(
      columnIndex: columnIndex,
      upperBeadActive: upper,
      lowerBeadsActive: lower,
    );
  }

  @override
  List<Object?> get props => [columnIndex, upperBeadActive, lowerBeadsActive];
}
