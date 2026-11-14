class BeadState {
  final bool isUpper;
  final bool isActive;
  final double currentY; // Tọa độ Y nội tại phục vụ animation trượt mượt mà

  const BeadState({
    required this.isUpper,
    required this.isActive,
    this.currentY = 0.0,
  });

  BeadState copyWith({
    bool? isUpper,
    bool? isActive,
    double? currentY,
  }) {
    return BeadState(
      isUpper: isUpper ?? this.isUpper,
      isActive: isActive ?? this.isActive,
      currentY: currentY ?? this.currentY,
    );
  }
}
