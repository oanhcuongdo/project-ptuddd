import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Nền minh họa chuyên biệt cho cụm màn hình Xác thực (Đăng nhập, Đăng ký, Khóa, Splash):
/// kết hợp dải chuyển sắc xanh hải quân tin cậy, đường cong lộ trình xe máy,
/// họa tiết vạch kẻ đường & ánh sáng ấm tạo chiều sâu thị giác (Figure-Ground).
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    super.key,
    required this.child,
    this.heroFraction = 0.46,
    this.showBottomRoadAccent = true,
  });

  final Widget child;

  /// Tỷ lệ chiều cao dải nền xanh phía trên (0.34 cho Đăng ký, 0.46 cho Đăng nhập).
  final double heroFraction;
  final bool showBottomRoadAccent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Lớp nền sáng thoáng phía dưới (60% canvas trung tính)
        const ColoredBox(color: AppColors.canvas),

        // Lớp đồ họa vector: dải gradient xanh, quầng sáng, đường lộ trình & sóng cong
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AuthBackdropPainter(
                heroFraction: heroFraction,
                showBottomRoadAccent: showBottomRoadAccent,
              ),
            ),
          ),
        ),

        // Nội dung chính nổi bật phía trên
        child,
      ],
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  const _AuthBackdropPainter({
    required this.heroFraction,
    required this.showBottomRoadAccent,
  });

  final double heroFraction;
  final bool showBottomRoadAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final heroHeight = size.height * heroFraction;

    // 1. Vùng hero trên với đường cong mềm mại chuyển xuống nền sáng
    final heroPath = Path()
      ..lineTo(0, heroHeight - 28)
      ..quadraticBezierTo(
        size.width * 0.28,
        heroHeight + 28,
        size.width * 0.62,
        heroHeight - 8,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        heroHeight - 32,
        size.width,
        heroHeight + 10,
      )
      ..lineTo(size.width, 0)
      ..close();

    final heroPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF071E36),
          AppColors.navyBrand,
          AppColors.primaryLight,
        ],
        stops: [0.0, 0.56, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, heroHeight + 40));

    canvas.drawPath(heroPath, heroPaint);

    // 2. Các quầng sáng ambient tinh tế (xanh da trời & cam đèn pha ấm)
    canvas.save();
    canvas.clipPath(heroPath);

    final topRightGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.skyAccent.withValues(alpha: 0.28),
          AppColors.skyAccent.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, heroHeight * 0.16),
          radius: size.width * 0.52,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.88, heroHeight * 0.16),
      size.width * 0.52,
      topRightGlow,
    );

    final leftWarmGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.motoOrange.withValues(alpha: 0.22),
          AppColors.motoOrange.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, heroHeight * 0.72),
          radius: size.width * 0.45,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.1, heroHeight * 0.72),
      size.width * 0.45,
      leftWarmGlow,
    );

    // 3. Lưới điểm tọa độ bản đồ mờ (tương đồng thế giới thực: định vị GPS)
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const step = 28.0;
    for (double x = 18; x < size.width; x += step) {
      for (double y = 18; y < heroHeight; y += step) {
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }

    // 4. Dải cung đường lộ trình kèm vạch phân làn đứt quãng
    final routeArc = Path()
      ..moveTo(-24, heroHeight * 0.78)
      ..cubicTo(
        size.width * 0.26,
        heroHeight * 0.34,
        size.width * 0.64,
        heroHeight * 0.92,
        size.width + 24,
        heroHeight * 0.24,
      );

    canvas.drawPath(
      routeArc,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );

    _drawDashedPath(
      canvas,
      routeArc,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
      dashLength: 10,
      gapLength: 10,
    );

    // Vòng radar định vị mờ góc trên trái
    final radarCenter = Offset(size.width * 0.14, heroHeight * 0.24);
    for (final r in [22.0, 44.0, 68.0]) {
      canvas.drawCircle(
        radarCenter,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawCircle(
      radarCenter,
      4.5,
      Paint()..color = AppColors.motoAmber.withValues(alpha: 0.75),
    );

    canvas.restore();

    // 5. Viền sóng ánh sáng nhẹ dọc theo đường chuyển giao giữa nền xanh và nền sáng
    final waveEdge = Path()
      ..moveTo(0, heroHeight - 28)
      ..quadraticBezierTo(
        size.width * 0.28,
        heroHeight + 28,
        size.width * 0.62,
        heroHeight - 8,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        heroHeight - 32,
        size.width,
        heroHeight + 10,
      );

    canvas.drawPath(
      waveEdge,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.motoOrange.withValues(alpha: 0.55),
            AppColors.skyAccent.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(0, heroHeight - 40, size.width, 80))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 6. Điểm nhấn nhẹ ở góc dưới nền sáng để không gian không bị trống
    if (showBottomRoadAccent) {
      final bottomGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.09),
            AppColors.primaryLight.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.92, size.height * 0.94),
            radius: size.width * 0.48,
          ),
        );
      canvas.drawCircle(
        Offset(size.width * 0.92, size.height * 0.94),
        size.width * 0.48,
        bottomGlow,
      );

      final bottomArc = Path()
        ..moveTo(-20, size.height * 0.93)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.86,
          size.width + 20,
          size.height * 0.97,
        );
      _drawDashedPath(
        canvas,
        bottomArc,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
        dashLength: 12,
        gapLength: 12,
      );
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter oldDelegate) =>
      oldDelegate.heroFraction != heroFraction ||
      oldDelegate.showBottomRoadAccent != showBottomRoadAccent;
}
