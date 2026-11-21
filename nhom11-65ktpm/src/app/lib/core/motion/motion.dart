import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Bộ chuyển động dùng chung, mô phỏng cảm giác lò xo (spring) của iOS 26
/// kết hợp các đường cong "emphasized" của Material 3 Expressive.
abstract final class AppMotion {
  /// Lò xo nhanh, hơi nảy: dùng cho phản hồi chạm (nút, thẻ).
  static const SpringDescription snappy = SpringDescription(mass: 1, stiffness: 520, damping: 26);

  /// Lò xo mềm, nảy rõ: dùng cho phần tử xuất hiện (bong bóng chat, thẻ).
  static const SpringDescription bouncy = SpringDescription(mass: 1, stiffness: 260, damping: 18);

  /// Lò xo êm, không nảy: dùng cho thay đổi kích thước / bố cục.
  static const SpringDescription smooth = SpringDescription(mass: 1, stiffness: 300, damping: 32);

  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration long = Duration(milliseconds: 560);

  /// Đường cong "emphasized decelerate" của Material 3.
  static const Curve emphasized = Cubic(0.05, 0.7, 0.1, 1.0);

  static final Curve springBouncy = SpringCurve(bouncy);
  static final Curve springSmooth = SpringCurve(smooth);
  static final Curve springSnappy = SpringCurve(snappy);
}

/// Biến một [SpringDescription] thành [Curve] để dùng với các implicit animation
/// (AnimatedScale, AnimatedContainer, TweenAnimationBuilder...).
class SpringCurve extends Curve {
  final SpringDescription spring;
  late final SpringSimulation _sim = SpringSimulation(spring, 0, 1, 0);
  late final double _settle = _settleTime();

  SpringCurve(this.spring);

  double _settleTime() {
    var t = 0.0;
    while (t < 3 && !_sim.isDone(t)) {
      t += 1 / 120;
    }
    return t == 0 ? 1 : t;
  }

  @override
  double transformInternal(double t) => _sim.x(t * _settle);
}

/// Bọc một widget để có phản hồi chạm kiểu iOS 26: co lại khi nhấn,
/// bật lại bằng lò xo khi thả, kèm rung nhẹ (haptic).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _animateTo(double target, SpringDescription spring) {
    _c.animateWith(SpringSimulation(spring, _c.value, target, _c.velocity));
  }

  void _down(_) {
    if (!_enabled) return;
    _animateTo(widget.pressedScale, AppMotion.snappy);
  }

  void _up([_]) => _animateTo(1, AppMotion.bouncy);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: _enabled,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.mediumImpact();
                widget.onLongPress!();
              },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Transform.scale(scale: _c.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hiệu ứng xuất hiện: mờ dần + trượt lên + phóng nhẹ bằng lò xo.
/// Dùng [index] để tạo hiệu ứng lần lượt (stagger) trong danh sách.
class EntranceAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration stagger;
  final Duration delay;
  final Offset offset;
  final double fromScale;
  final bool enabled;
  final Alignment scaleAlignment;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 45),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 18),
    this.fromScale = 0.94,
    this.enabled = true,
    this.scaleAlignment = Alignment.center,
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: widget.enabled ? 0 : 1,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    final wait = widget.delay + widget.stagger * widget.index;
    if (wait == Duration.zero) {
      _play();
    } else {
      _timer = Timer(wait, _play);
    }
  }

  void _play() {
    if (!mounted) return;
    _c.animateWith(SpringSimulation(AppMotion.bouncy, _c.value, 1, 0));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value;
        final opacity = v.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: widget.offset * (1 - v),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * v,
              alignment: widget.scaleAlignment,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Chuyển đổi giữa hai widget (vd. icon mic ↔ stop) bằng cách mờ + xoay + phóng lò xo.
class MorphSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const MorphSwitcher({super.key, required this.child, this.duration = AppMotion.medium});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.springBouncy,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation.drive(const ClampedProgress(end: 0.6)),
        child: ScaleTransition(
          scale: animation.drive(Tween(begin: 0.6, end: 1.0)),
          child: RotationTransition(
            turns: animation.drive(Tween(begin: -0.08, end: 0.0)),
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Chuẩn hoá tiến trình về [0, 1] (lò xo có thể vượt quá 1) và kéo giãn
/// sao cho đạt 1 tại [end]. Dùng cho opacity khi animation dùng đường cong lò xo.
class ClampedProgress extends Animatable<double> {
  final double end;

  const ClampedProgress({this.end = 1});

  @override
  double transform(double t) => (t / end).clamp(0.0, 1.0);
}
