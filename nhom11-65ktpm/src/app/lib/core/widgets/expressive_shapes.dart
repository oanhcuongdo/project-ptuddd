import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hình "bánh quy" lượn sóng trong bộ hình khối Material 3 Expressive
/// (Cookie / Sunny / Clover). Dùng làm nền icon để tạo điểm nhấn vui mắt.
class CookieBorder extends OutlinedBorder {
  /// Số múi lượn.
  final int lobes;

  /// Độ sâu múi (0–0.2). 0 = hình tròn.
  final double depth;

  /// Góc xoay (radian) – có thể tạo animation xoay nhẹ.
  final double rotation;

  const CookieBorder({this.lobes = 9, this.depth = 0.07, this.rotation = 0, super.side});

  Path _path(Rect rect) {
    final c = rect.center;
    final r = rect.shortestSide / 2;
    final path = Path();
    const steps = 144;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final rr = r * (1 - depth + depth * math.cos(lobes * t));
      final p = Offset(c.dx + rr * math.cos(t + rotation), c.dy + rr * math.sin(t + rotation));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  CookieBorder copyWith({BorderSide? side, int? lobes, double? depth, double? rotation}) => CookieBorder(
        lobes: lobes ?? this.lobes,
        depth: depth ?? this.depth,
        rotation: rotation ?? this.rotation,
        side: side ?? this.side,
      );

  @override
  ShapeBorder scale(double t) => copyWith(side: side.scale(t));

  @override
  bool operator ==(Object other) =>
      other is CookieBorder &&
      other.lobes == lobes &&
      other.depth == depth &&
      other.rotation == rotation &&
      other.side == side;

  @override
  int get hashCode => Object.hash(lobes, depth, rotation, side);
}

/// Biểu tượng đặt trong hình Cookie màu, xoay nhẹ một lần khi xuất hiện.
class CookieIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final int lobes;

  const CookieIcon({super.key, required this.icon, required this.color, this.size = 48, this.lobes = 9});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -0.6, end: 0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, turn, child) => DecoratedBox(
        decoration: ShapeDecoration(
          shape: CookieBorder(lobes: lobes, rotation: turn),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: dark ? 0.45 : 0.22),
              color.withValues(alpha: dark ? 0.30 : 0.12),
            ],
          ),
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, color: dark ? Color.lerp(color, Colors.white, 0.35) : color, size: size * 0.48),
      ),
    );
  }
}
