import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Biểu tượng thương hiệu có hiệu ứng chiếc xe máy chạy dọc con đường từ bên trái
/// tiến vào khung logo trung tâm, phanh êm, tỏa vòng sáng định vị và dừng gọn gàng.
/// Chạm vào logo để xem lại hiệu ứng chạy xe.
class AnimatedMotoLogo extends StatefulWidget {
  const AnimatedMotoLogo({
    super.key,
    this.badgeSize = 84,
    this.trackWidth = 240,
    this.interactive = true,
  });

  final double badgeSize;
  final double trackWidth;
  final bool interactive;

  @override
  State<AnimatedMotoLogo> createState() => _AnimatedMotoLogoState();
}

class _AnimatedMotoLogoState extends State<AnimatedMotoLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1850),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    if (!widget.interactive) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final height = widget.badgeSize + 24;

    final canvas = SizedBox(
      width: widget.trackWidth,
      height: height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = disableAnimations ? 1.0 : _controller.value;
          return CustomPaint(
            painter: _MotoIntoLogoPainter(
              progress: progress,
              badgeSize: widget.badgeSize,
            ),
          );
        },
      ),
    );

    if (!widget.interactive) return canvas;

    return Tooltip(
      message: 'Chạm để xem lại hiệu ứng xe máy',
      child: GestureDetector(
        onTap: _replay,
        behavior: HitTestBehavior.opaque,
        child: canvas,
      ),
    );
  }
}

class _MotoIntoLogoPainter extends CustomPainter {
  const _MotoIntoLogoPainter({
    required this.progress,
    required this.badgeSize,
  });

  final double progress;
  final double badgeSize;

  double _interval(double start, double end, Curve curve) {
    if (progress <= start) return 0;
    if (progress >= end) return 1;
    return curve.transform((progress - start) / (end - start));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Giai đoạn 1: Khung logo mở ra (0.00 -> 0.28)
    final badgeScale = 0.72 + 0.28 * _interval(0.0, 0.28, Curves.easeOutBack);
    final badgeOpacity = _interval(0.0, 0.20, Curves.easeOut);

    // Giai đoạn 2: Xe máy chạy từ mép trái vào tâm logo (0.10 -> 0.78)
    final rideT = _interval(0.10, 0.78, Curves.easeOutCubic);
    final bikeOpacity = _interval(0.08, 0.20, Curves.easeOut);

    // Giai đoạn 3: Sóng ánh sáng định vị lan tỏa khi xe dừng đúng vị trí (0.70 -> 1.00)
    final pulseT = _interval(0.70, 1.0, Curves.easeOutQuart);
    final roadAlpha = (1.0 - _interval(0.74, 0.96, Curves.easeInOut)) *
        _interval(0.04, 0.18, Curves.easeOut);

    final badgeRect = Rect.fromCenter(
      center: center,
      width: badgeSize * badgeScale,
      height: badgeSize * badgeScale,
    );
    final badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      Radius.circular(badgeSize * 0.28 * badgeScale),
    );

    // 1. Vòng sóng radar định vị tỏa ra khi xe dừng vào logo
    if (pulseT > 0 && pulseT < 1) {
      final rippleRadius = badgeSize * (0.52 + 0.44 * pulseT);
      canvas.drawCircle(
        center,
        rippleRadius,
        Paint()
          ..color = AppColors.motoAmber.withValues(alpha: 0.48 * (1 - pulseT))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * (1 - pulseT * 0.5),
      );

      final secondRipple = badgeSize * (0.48 + 0.62 * pulseT);
      canvas.drawCircle(
        center,
        secondRipple,
        Paint()
          ..color = AppColors.skyAccent.withValues(alpha: 0.34 * (1 - pulseT))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // 2. Đường chạy tạm thời bên ngoài logo (tự mờ gọn sau khi xe dừng)
    if (roadAlpha > 0.01) {
      final roadY = center.dy + badgeSize * 0.24;
      final roadPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.24 * roadAlpha)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(10, roadY),
        Offset(size.width - 10, roadY),
        roadPaint,
      );

      // Vạch kẻ đường trôi ngược chiều tạo cảm giác tốc độ
      final dashPaint = Paint()
        ..color = AppColors.motoAmber.withValues(alpha: 0.55 * roadAlpha)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final scroll = (rideT * 110) % 24;
      for (double x = 16 - scroll; x < size.width - 16; x += 24) {
        final startX = x.clamp(12.0, size.width - 12.0);
        final endX = (x + 11).clamp(12.0, size.width - 12.0);
        if (endX > startX + 2) {
          canvas.drawLine(Offset(startX, roadY + 5), Offset(endX, roadY + 5), dashPaint);
        }
      }
    }

    // 3. Đổ bóng & khung logo bo tròn (gradient xanh biển + viền ánh sáng)
    if (badgeOpacity > 0) {
      canvas.save();
      canvas.drawRRect(
        badgeRRect.shift(const Offset(0, 7)),
        Paint()
          ..color = AppColors.navyDeep.withValues(alpha: 0.34 * badgeOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      final bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            AppColors.primary,
            Color(0xFF0F3D6E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(badgeRect);
      canvas.drawRRect(badgeRRect, bgPaint);

      // Ánh sáng phản chiếu nhẹ phía trên logo
      final glossRect = Rect.fromLTWH(
        badgeRect.left + 4,
        badgeRect.top + 3,
        badgeRect.width - 8,
        badgeRect.height * 0.44,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(glossRect, Radius.circular(badgeSize * 0.22)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.26 * badgeOpacity),
              Colors.white.withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(glossRect),
      );

      // Viền sáng bao quanh logo (rực nhẹ khi xe vừa vào khớp)
      final glowBoost = math.sin(pulseT * math.pi) * 0.45;
      canvas.drawRRect(
        badgeRRect,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (0.45 + glowBoost).clamp(0.0, 0.95) * badgeOpacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );

      // Dải nhấn cam góc dưới bên trong logo
      canvas.clipRRect(badgeRRect);
      final groundShadowY = center.dy + badgeSize * 0.24;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, groundShadowY + 1),
          width: badgeSize * 0.62 * rideT,
          height: 6.5,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.28 * rideT),
      );

      // Vạch cung định vị mảnh bên trong logo
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: badgeSize * 0.39),
        -math.pi * 0.78,
        math.pi * 0.56,
        false,
        Paint()
          ..color = AppColors.motoAmber.withValues(alpha: 0.55 * rideT)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );

      canvas.restore();
    }

    // 4. Chiếc xe máy chạy từ trái vào tâm logo
    if (bikeOpacity > 0.01) {
      final startX = 24.0;
      final endX = center.dx;
      final bikeX = startX + (endX - startX) * rideT;

      // Tốc độ tức thời gần đúng để tính độ rung phuộc, nghiêng xe & vệt gió
      final speedFactor = (1.0 - rideT).clamp(0.0, 1.0);
      final suspensionBounce =
          math.sin(rideT * math.pi * 9) * 1.8 * speedFactor;
      final brakeTilt = rideT > 0.62 && rideT < 0.96
          ? math.sin(((rideT - 0.62) / 0.34) * math.pi) * 0.055
          : -0.04 * speedFactor;

      final bikeY = center.dy + badgeSize * 0.04 + suspensionBounce;
      final wheelAngle = rideT * math.pi * 6.5;
      final bikeScale = badgeSize / 84.0;

      // Vệt gió tốc độ & khói nhẹ phía sau xe khi đang chạy
      if (speedFactor > 0.04) {
        _drawSpeedLines(
          canvas,
          origin: Offset(bikeX - 24 * bikeScale, bikeY),
          scale: bikeScale,
          intensity: speedFactor * bikeOpacity,
        );
      }

      canvas.save();
      canvas.translate(bikeX, bikeY);
      canvas.rotate(brakeTilt);
      canvas.scale(bikeScale);
      _drawMotorbike(
        canvas,
        wheelAngle: wheelAngle,
        headlightAlpha: (0.28 + 0.55 * speedFactor + 0.25 * math.sin(pulseT * math.pi))
            .clamp(0.0, 0.9) *
            bikeOpacity,
        opacity: bikeOpacity,
      );
      canvas.restore();
    }

    // 5. Điểm sáng lấp lánh nhẹ ở góc trên phải khi xe đã đỗ gọn trong logo
    if (pulseT > 0.15) {
      final sparkleAlpha = math.sin(((pulseT - 0.15) / 0.85) * math.pi);
      if (sparkleAlpha > 0.02) {
        _drawSparkle(
          canvas,
          Offset(badgeRect.right - 14, badgeRect.top + 14),
          6.5 * sparkleAlpha,
          Colors.white.withValues(alpha: 0.9 * sparkleAlpha),
        );
      }
    }
  }

  void _drawSpeedLines(
    Canvas canvas, {
    required Offset origin,
    required double scale,
    required double intensity,
  }) {
    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0 * scale;

    final lengths = [22.0, 32.0, 16.0];
    final yOffsets = [-9.0, 0.0, 8.5];
    for (var i = 0; i < 3; i++) {
      final len = lengths[i] * scale * (0.45 + 0.55 * intensity);
      final y = origin.dy + yOffsets[i] * scale;
      linePaint.color = (i == 1 ? AppColors.motoAmber : Colors.white)
          .withValues(alpha: 0.62 * intensity);
      canvas.drawLine(
        Offset(origin.dx - len, y),
        Offset(origin.dx, y),
        linePaint,
      );
    }

    // Hạt khí xả tròn nhỏ mờ dần phía sau ống pô
    for (var i = 0; i < 2; i++) {
      final puffOffset = Offset(
        origin.dx - (10 + i * 11) * scale,
        origin.dy + (10 - i * 2.5) * scale,
      );
      canvas.drawCircle(
        puffOffset,
        (2.4 + i * 1.4) * scale,
        Paint()..color = Colors.white.withValues(alpha: 0.26 * intensity),
      );
    }
  }

  /// Vẽ chiếc xe máy phong cách hiện đại (tọa độ chuẩn xung quanh gốc (0, 0)).
  void _drawMotorbike(
    Canvas canvas, {
    required double wheelAngle,
    required double headlightAlpha,
    required double opacity,
  }) {
    const rearWheel = Offset(-16.5, 11.5);
    const frontWheel = Offset(17.5, 11.5);
    const wheelRadius = 8.4;

    // Tia sáng đèn pha chiếu về phía trước
    if (headlightAlpha > 0.02) {
      final beam = Path()
        ..moveTo(19.5, -5.5)
        ..lineTo(43, -13)
        ..lineTo(43, 4.5)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFFF59D).withValues(alpha: headlightAlpha * 0.85),
              const Color(0xFFFFF59D).withValues(alpha: 0.0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(const Rect.fromLTWH(19, -14, 25, 20)),
      );
    }

    // Bánh sau & bánh trước với nan hoa quay mượt
    _drawWheel(canvas, rearWheel, wheelRadius, wheelAngle, opacity);
    _drawWheel(canvas, frontWheel, wheelRadius, wheelAngle, opacity);

    // Ống pô màu bạc gọn phía sau
    canvas.drawLine(
      const Offset(-23, 10),
      const Offset(-10, 8),
      Paint()
        ..color = const Color(0xFFCBD5E1).withValues(alpha: opacity)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // Khung gầm & phuộc trước
    final framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * opacity)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Phuộc trước từ ghi-đông xuống trục bánh trước
    canvas.drawLine(const Offset(10, -10), frontWheel, framePaint);
    // Ghi-đông & gương
    canvas.drawLine(
      const Offset(8.5, -10.5),
      const Offset(13.5, -12),
      framePaint,
    );

    // Chắn bùn trước màu cam cứu hộ
    canvas.drawArc(
      Rect.fromCircle(center: frontWheel, radius: wheelRadius + 2.4),
      -math.pi * 0.88,
      math.pi * 0.56,
      false,
      Paint()
        ..color = AppColors.motoOrange.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Thân xe & yếm trước sắc nét màu trắng sáng
    final bodyPath = Path()
      ..moveTo(-21, 1.5) // đuôi xe
      ..lineTo(-9, -2.5) // phần yên sau
      ..quadraticBezierTo(-1, -4.5, 4.5, 1.5) // hõm thân xe
      ..lineTo(10.5, -8.5) // mặt nạ trước
      ..quadraticBezierTo(16.5, -9, 19.5, -4.5) // đầu đèn pha
      ..quadraticBezierTo(15.5, 4.5, 9, 8.5) // yếm dưới
      ..lineTo(-7, 9.5) // gầm động cơ
      ..quadraticBezierTo(-15, 7, -21, 1.5)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    // Dải tem thân xe màu cam nổi bật (nhận diện thương hiệu cứu hộ xe máy)
    final stripePath = Path()
      ..moveTo(-16.5, 2.2)
      ..lineTo(-6, 0.4)
      ..lineTo(13, -4.2)
      ..lineTo(10.5, 0.8)
      ..lineTo(-6.5, 4.6)
      ..close();
    canvas.drawPath(
      stripePath,
      Paint()..color = AppColors.motoOrange.withValues(alpha: opacity),
    );

    // Yên xe màu xanh navy đậm
    final seatPath = Path()
      ..moveTo(-19.5, -0.5)
      ..quadraticBezierTo(-10, -5.2, -1.5, -2.5)
      ..lineTo(-2.5, 0.4)
      ..lineTo(-18.5, 1.6)
      ..close();
    canvas.drawPath(
      seatPath,
      Paint()..color = AppColors.navyDeep.withValues(alpha: opacity),
    );

    // Cụm đèn pha sáng ấm & đèn hậu đỏ
    canvas.drawCircle(
      const Offset(18.5, -5.2),
      2.4,
      Paint()..color = const Color(0xFFFFF176).withValues(alpha: opacity),
    );
    canvas.drawCircle(
      const Offset(-20.2, 1.2),
      1.7,
      Paint()..color = AppColors.sosRed.withValues(alpha: opacity),
    );
  }

  void _drawWheel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    double opacity,
  ) {
    // Lốp ngoài
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF0F172A).withValues(alpha: 0.92 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
    // Vành bánh xe sáng
    canvas.drawCircle(
      center,
      radius - 2.1,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 4 nan hoa quay theo bánh xe
    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78 * opacity)
      ..strokeWidth = 1.1;
    for (var i = 0; i < 4; i++) {
      final theta = angle + i * (math.pi / 2);
      final dx = math.cos(theta) * (radius - 2.3);
      final dy = math.sin(theta) * (radius - 2.3);
      canvas.drawLine(
        center,
        Offset(center.dx + dx, center.dy + dy),
        spokePaint,
      );
    }

    // Tâm trục màu cam
    canvas.drawCircle(
      center,
      1.9,
      Paint()..color = AppColors.motoAmber.withValues(alpha: opacity),
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MotoIntoLogoPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.badgeSize != badgeSize;
}
