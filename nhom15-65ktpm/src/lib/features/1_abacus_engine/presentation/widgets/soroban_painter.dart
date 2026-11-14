import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/soroban_column.dart';

class SorobanPainter extends CustomPainter {
  final List<SorobanColumn> columns;
  final bool showColumnValues;

  SorobanPainter({
    required this.columns,
    this.showColumnValues = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = AppColors.abacusFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final frameFillPaint = Paint()
      ..color = const Color(0xFFFFF8F0)
      ..style = PaintingStyle.fill;

    // Vẽ nền trong bàn tính
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, frameFillPaint);

    final beamY = size.height * 0.32;
    final beamHeight = 14.0;

    final colWidth = size.width / columns.length;

    // 1. Vẽ các thanh xỏ dọc (Rods)
    final rodPaint = Paint()
      ..color = AppColors.abacusRod
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < columns.length; i++) {
      final rodX = colWidth * i + colWidth / 2;
      canvas.drawLine(
        Offset(rodX, 10),
        Offset(rodX, size.height - 10),
        rodPaint,
      );
    }

    // 2. Vẽ các hạt bàn tính (Beads)
    for (int i = 0; i < columns.length; i++) {
      final col = columns[i];
      final colCenterX = colWidth * i + colWidth / 2;
      final beadWidth = colWidth * 0.78;
      final beadHeight = size.height * 0.085;

      // Hạt trên (Upper Bead - Giá trị 5)
      // Khi active: chạm thanh xà ngang (beamY)
      // Khi inactive: sát mép trên
      final upperActiveY = beamY - (beadHeight / 2) - 2;
      final upperInactiveY = 16.0 + (beadHeight / 2);
      final upperY = col.upperBeadActive ? upperActiveY : upperInactiveY;

      _drawSorobanBead(
        canvas: canvas,
        center: Offset(colCenterX, upperY),
        width: beadWidth,
        height: beadHeight,
        color: col.upperBeadActive ? AppColors.beadActive : AppColors.beadUpper,
        isActive: col.upperBeadActive,
      );

      // 4 Hạt dưới (Lower Beads - Mỗi hạt giá trị 1)
      final lowerSpaceStart = beamY + beamHeight + 4;
      final lowerSpaceEnd = size.height - 16;
      final activeCount = col.lowerBeadsActive; // 0..4

      // Các hạt active được đẩy lên sát beam
      for (int b = 0; b < activeCount; b++) {
        final bY = lowerSpaceStart + (b * (beadHeight + 2)) + (beadHeight / 2);
        _drawSorobanBead(
          canvas: canvas,
          center: Offset(colCenterX, bY),
          width: beadWidth,
          height: beadHeight,
          color: AppColors.beadActive,
          isActive: true,
        );
      }

      // Các hạt inactive nằm ở phía dưới đáy
      final inactiveCount = 4 - activeCount;
      for (int b = 0; b < inactiveCount; b++) {
        final bY = lowerSpaceEnd -
            ((inactiveCount - 1 - b) * (beadHeight + 2)) -
            (beadHeight / 2);
        _drawSorobanBead(
          canvas: canvas,
          center: Offset(colCenterX, bY),
          width: beadWidth,
          height: beadHeight,
          color: AppColors.beadLower,
          isActive: false,
        );
      }
    }

    // 3. Vẽ thanh xà ngang (Beam)
    final beamPaint = Paint()
      ..color = AppColors.abacusBeam
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, beamY - beamHeight / 2, size.width, beamHeight),
      beamPaint,
    );

    // Vẽ điểm định vị trên beam (Unit dot)
    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < columns.length; i++) {
      if ((columns.length - 1 - i) % 3 == 0) {
        final dotX = colWidth * i + colWidth / 2;
        canvas.drawCircle(Offset(dotX, beamY), 3.5, dotPaint);
      }
    }

    // 4. Vẽ khung ngoài (Outer Frame)
    canvas.drawRRect(rrect, framePaint);
  }

  void _drawSorobanBead({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required Color color,
    required bool isActive,
  }) {
    // Vẽ hạt hình quả trám Soroban (biconical/diamond-like rounded hexagon)
    final path = Path();
    final halfW = width / 2;
    final halfH = height / 2;

    path.moveTo(center.dx - halfW, center.dy);
    path.lineTo(center.dx - halfW * 0.6, center.dy - halfH);
    path.lineTo(center.dx + halfW * 0.6, center.dy - halfH);
    path.lineTo(center.dx + halfW, center.dy);
    path.lineTo(center.dx + halfW * 0.6, center.dy + halfH);
    path.lineTo(center.dx - halfW * 0.6, center.dy + halfH);
    path.close();

    // Đổ bóng hạt
    final shadowPath = path.shift(const Offset(0, 3));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Thân hạt với gradient
    final beadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.9),
          color,
          color.withBlue((color.blue - 30).clamp(0, 255)),
        ],
      ).createShader(Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      ));

    canvas.drawPath(path, beadPaint);

    // Đường gân phản chiếu ở giữa hạt
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx - halfW * 0.8, center.dy),
      Offset(center.dx + halfW * 0.8, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SorobanPainter oldDelegate) {
    return true;
  }
}
