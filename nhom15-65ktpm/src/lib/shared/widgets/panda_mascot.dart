import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum PandaExpression { happy, encouraging, celebrating }

class PandaMascot extends StatelessWidget {
  final double size;
  final PandaExpression expression;
  final ImageProvider? image;

  const PandaMascot({
    super.key,
    required this.expression,
    this.image,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = image;
    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return CustomPaint(
      size: Size.square(size),
      painter: _PandaPainter(expression),
    );
  }
}

class _PandaPainter extends CustomPainter {
  final PandaExpression expression;

  const _PandaPainter(this.expression);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale, size.height / 100);

    final black = Paint()..color = const Color(0xFF252638);
    final white = Paint()..color = Colors.white;
    final faceOutline = Paint()
      ..color = const Color(0xFFE1E5EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(const Offset(24, 22), 16, black);
    canvas.drawCircle(const Offset(76, 22), 16, black);
    canvas.drawCircle(const Offset(50, 53), 42, white);
    canvas.drawCircle(const Offset(50, 53), 42, faceOutline);

    canvas.save();
    canvas.translate(37, 47);
    canvas.rotate(-0.2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 21, height: 29),
      black,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(63, 47);
    canvas.rotate(0.2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 21, height: 29),
      black,
    );
    canvas.restore();

    final eye = Paint()..color = Colors.white;
    final pupil = Paint()..color = const Color(0xFF15151C);
    canvas.drawCircle(const Offset(39, 47), 5, eye);
    canvas.drawCircle(const Offset(61, 47), 5, eye);
    canvas.drawCircle(const Offset(40, 48), 2.5, pupil);
    canvas.drawCircle(const Offset(60, 48), 2.5, pupil);

    final cheek = Paint()..color = AppColors.primary.withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(26, 63), width: 12, height: 7),
      cheek,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(74, 63), width: 12, height: 7),
      cheek,
    );

    final nose = Paint()..color = const Color(0xFF252638);
    final nosePath = Path()
      ..moveTo(45, 59)
      ..quadraticBezierTo(50, 55, 55, 59)
      ..quadraticBezierTo(50, 66, 45, 59);
    canvas.drawPath(nosePath, nose);

    final mouthPaint = Paint()
      ..color = const Color(0xFF252638)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    if (expression == PandaExpression.happy) {
      final smile = Path()
        ..moveTo(43, 68)
        ..quadraticBezierTo(50, 76, 57, 68);
      canvas.drawPath(smile, mouthPaint);
    } else {
      final mouthFill = Paint()..color = const Color(0xFF252638);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(50, 70),
          width: expression == PandaExpression.celebrating ? 13 : 10,
          height: expression == PandaExpression.celebrating ? 15 : 12,
        ),
        mouthFill,
      );
      if (expression == PandaExpression.celebrating) {
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(50, 75),
            width: 7,
            height: 4,
          ),
          Paint()..color = AppColors.primary,
        );
      }
    }

    if (expression == PandaExpression.celebrating) {
      final confettiColors = [
        AppColors.secondary,
        AppColors.accentPurple,
        AppColors.primary,
      ];
      for (var index = 0; index < confettiColors.length; index++) {
        canvas.drawCircle(
          Offset(8 + index * 8, 24 - (index % 2) * 8),
          3,
          Paint()..color = confettiColors[index],
        );
        canvas.drawCircle(
          Offset(76 + index * 8, 16 + (index % 2) * 8),
          3,
          Paint()..color = confettiColors[index],
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PandaPainter oldDelegate) {
    return oldDelegate.expression != expression;
  }
}
