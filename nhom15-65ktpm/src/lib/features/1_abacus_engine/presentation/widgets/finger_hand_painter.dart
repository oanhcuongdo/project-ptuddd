import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/finger_hand_state.dart';

class FingerHandPainter extends CustomPainter {
  final FingerHandState handState;
  final bool isInteractive;

  FingerHandPainter({
    required this.handState,
    this.isInteractive = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final isRight = handState.handType == HandType.rightHand;

    // Màu sắc da hoạt hình
    const skinColor = Color(0xFFFFDFBA);
    final outlinePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final skinPaint = Paint()
      ..color = skinColor
      ..style = PaintingStyle.fill;

    final activeThumbPaint = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.fill;

    final activeFingerPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    // Tọa độ tâm lòng bàn tay
    final palmCenter = Offset(w * 0.5, h * 0.65);
    final palmWidth = w * 0.52;
    final palmHeight = h * 0.38;

    // 1. Vẽ 4 ngón dài (Trỏ, Giữa, Áp út, Út)
    final fingerWidth = palmWidth * 0.22;
    final maxFingerHeight = h * 0.42;

    // Vị trí các ngón từ trái qua phải tùy thuộc tay trái hay tay phải
    // Với tay phải nhìn từ lòng bàn tay: Ngón cái ở bên trái, tiếp theo là Trỏ, Giữa, Áp út, Út
    for (int i = 0; i < 4; i++) {
      // i = 0: Trỏ, 1: Giữa, 2: Áp út, 3: Út
      final isExtended = i < handState.extendedFingersCount;

      final fingerX = isRight
          ? (w * 0.38 + (i * fingerWidth * 1.05))
          : (w * 0.62 - (i * fingerWidth * 1.05));

      final fingerLength = isExtended
          ? maxFingerHeight * (1.0 - (i == 3 ? 0.15 : (i == 1 ? -0.05 : 0.0)))
          : h * 0.12;

      final fingerTopY = isExtended
          ? (palmCenter.dy - palmHeight * 0.4 - fingerLength)
          : (palmCenter.dy - palmHeight * 0.3);

      final fingerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(fingerX, fingerTopY + fingerLength / 2),
          width: fingerWidth,
          height: fingerLength,
        ),
        Radius.circular(fingerWidth / 2),
      );

      // Đổ bóng ngón tay
      canvas.drawRRect(
        fingerRect.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Thân ngón tay
      canvas.drawRRect(
        fingerRect,
        isExtended ? activeFingerPaint : skinPaint,
      );
      canvas.drawRRect(fingerRect, outlinePaint);

      // Vẽ nếp gấp ngón tay
      if (isExtended) {
        final foldY1 = fingerTopY + fingerLength * 0.35;
        final foldY2 = fingerTopY + fingerLength * 0.65;
        final foldPaint = Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(fingerX - fingerWidth * 0.3, foldY1),
          Offset(fingerX + fingerWidth * 0.3, foldY1),
          foldPaint,
        );
        canvas.drawLine(
          Offset(fingerX - fingerWidth * 0.3, foldY2),
          Offset(fingerX + fingerWidth * 0.3, foldY2),
          foldPaint,
        );

        // Nhãn giá trị ngón tay: '1' ở Tay Phải, '10' ở Tay Trái
        final label = isRight ? '1' : '10';
        final textSpan = TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isRight ? fingerWidth * 0.55 : fingerWidth * 0.42,
            fontWeight: FontWeight.w900,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(fingerX - textPainter.width / 2, fingerTopY + fingerLength * 0.12),
        );
      }
    }

    // 2. Vẽ Lòng bàn tay (Palm)
    final palmRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: palmCenter,
        width: palmWidth,
        height: palmHeight,
      ),
      const Radius.circular(28),
    );

    // Bóng lòng bàn tay
    canvas.drawRRect(
      palmRRect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(palmRRect, skinPaint);
    canvas.drawRRect(palmRRect, outlinePaint);

    // 3. Vẽ Ngón cái (Thumb - 5 ở tay phải, 50 ở tay trái)
    // Tay phải: Ngón cái chìa sang bên trái
    // Tay trái: Ngón cái chìa sang bên phải
    final thumbIsExtended = handState.isThumbExtended;
    final thumbWidth = fingerWidth * 1.18;
    final thumbLength = thumbIsExtended ? h * 0.28 : h * 0.14;

    final thumbCenterX = isRight
        ? (thumbIsExtended ? w * 0.18 : w * 0.28)
        : (thumbIsExtended ? w * 0.82 : w * 0.72);

    final thumbCenterY = palmCenter.dy + (thumbIsExtended ? -h * 0.05 : h * 0.05);

    canvas.save();
    canvas.translate(thumbCenterX, thumbCenterY);
    // Xoay ngón cái nghiêng sang một bên
    final angle = isRight
        ? (thumbIsExtended ? -0.55 : 0.3)
        : (thumbIsExtended ? 0.55 : -0.3);
    canvas.rotate(angle);

    final thumbRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: thumbWidth,
        height: thumbLength,
      ),
      Radius.circular(thumbWidth / 2),
    );

    canvas.drawRRect(
      thumbRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawRRect(
      thumbRRect,
      thumbIsExtended ? activeThumbPaint : skinPaint,
    );
    canvas.drawRRect(thumbRRect, outlinePaint);

    // Nhãn '5' trên Tay Phải hoặc '50' trên Tay Trái khi ngón cái xòe
    if (thumbIsExtended) {
      final thumbText = isRight ? '5' : '50';
      final textSpan = TextSpan(
        text: thumbText,
        style: TextStyle(
          color: Colors.white,
          fontSize: isRight ? thumbWidth * 0.65 : thumbWidth * 0.50,
          fontWeight: FontWeight.w900,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
    }

    canvas.restore();

    // 4. Cổ tay (Wrist)
    final wristWidth = palmWidth * 0.7;
    final wristPath = Path()
      ..moveTo(palmCenter.dx - wristWidth / 2, palmCenter.dy + palmHeight * 0.45)
      ..lineTo(palmCenter.dx - wristWidth / 2, h * 0.98)
      ..lineTo(palmCenter.dx + wristWidth / 2, h * 0.98)
      ..lineTo(palmCenter.dx + wristWidth / 2, palmCenter.dy + palmHeight * 0.45);

    canvas.drawPath(wristPath, skinPaint);
    canvas.drawPath(wristPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant FingerHandPainter oldDelegate) {
    return oldDelegate.handState != handState;
  }
}
