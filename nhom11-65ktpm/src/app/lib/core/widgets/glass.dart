import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import '../theme/glass_theme.dart';
import 'expressive_shapes.dart';
import 'glass_lens.dart';

export '../motion/motion.dart';
export 'expressive_shapes.dart';
export 'glass_lens.dart' show GlassLens, LensOptics;

/// Ma trận tăng bão hoà màu nền phía sau kính (hiệu ứng "vibrancy" của iOS).
ui.ColorFilter _saturation(double s) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final a = 1 - s;
  return ui.ColorFilter.matrix([
    a * lr + s, a * lg, a * lb, 0, 0, //
    a * lr, a * lg + s, a * lb, 0, 0, //
    a * lr, a * lg, a * lb + s, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}

final ui.ColorFilter _vibrancy = _saturation(1.7);

/// Kính trong (không mờ) chỉ tăng bão hoà nhẹ để màu nền xuyên qua vẫn tự nhiên.
final ui.ColorFilter _clearVibrancy = _saturation(1.2);

/// Lớp vật liệu Liquid Glass: làm mờ + tăng bão hoà phần nền phía sau,
/// phủ một lớp kính trong, viền phản quang và bóng đổ mềm.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Màu kính tuỳ chỉnh (vd. kính nhuộm màu chủ đạo cho nút chính).
  final Color? tint;

  /// Dùng lớp kính dày hơn – cho thanh điều hướng, ô nhập, bottom sheet.
  final bool thick;
  final bool shadow;

  /// Độ nổi của bóng (1 = mặc định). Nút nhỏ dùng < 1 để bóng gọn, không loang.
  final double shadowScale;
  final bool blur;

  /// Thông số khúc xạ mép kính (chỉ có tác dụng khi shader khả dụng).
  final LensOptics optics;

  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTheme.radiusMedium)),
    this.padding,
    this.tint,
    this.thick = false,
    this.shadow = true,
    this.shadowScale = 1,
    this.blur = true,
    this.optics = const LensOptics(),
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    // Kính nằm TRONG một kính khác (nút trong thẻ...) không tự lấy mẫu nền:
    // Impeller đưa cho BackdropFilter lồng nhau một texture nền nhỏ, gốc toạ độ
    // khác màn hình nên shader khúc xạ lấy sai chỗ (lòng nút trắng, dải lệch ở
    // mép). Kính con chỉ vẽ lớp phủ đặc hơn + viền trên nền kính cha.
    final nested = _GlassScope.isInside(context);
    final fill = tint ?? (thick ? g.thickTint : (nested ? Color.lerp(g.tint, g.thickTint, 0.5)! : g.tint));
    final top = fill.withValues(alpha: (fill.a + 0.03).clamp(0.0, 1.0));

    Widget content = CustomPaint(
      foregroundPainter: _GlassRimPainter(borderRadius, g.rimHighlight, g.rimShade),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, fill]),
        ),
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
    if (blur && !(nested && GlassLens.available)) {
      ui.ImageFilter frosted(double sigma) => ui.ImageFilter.compose(
        outer: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.mirror),
        inner: _vibrancy,
      );
      // Có shader khúc xạ:
      // - kính thường: TRONG như kính thật (không làm mờ) – nhìn rõ nền phía
      //   sau và nền xung quanh bị bẻ cong vào mép;
      // - kính dày (thanh điều hướng, ô nhập, sheet): vẫn làm mờ để dễ đọc chữ.
      content = GlassLens.available
          ? LensBackdrop(
              radius: borderRadius.topLeft.x,
              baseFilter: thick ? frosted(g.blurSigma * 0.5) : _clearVibrancy,
              sampleOutside: !thick,
              // Nền tối: viền phản chiếu dịu hơn để không bị loá.
              optics: Theme.of(context).brightness == Brightness.dark
                  ? optics.copyWith(specular: optics.specular * 0.55)
                  : optics,
              child: content,
            )
          : BackdropFilter(filter: frosted(g.blurSigma), child: content);
    }
    content = ClipRSuperellipse(borderRadius: borderRadius, child: _GlassScope(child: content));
    if (shadow) {
      content = CustomPaint(painter: _OuterShadowPainter(borderRadius, g.shadows, shadowScale), child: content);
    }
    return content;
  }
}

/// Đánh dấu cây con nằm bên trong một [GlassSurface] (xem `nested` ở trên).
class _GlassScope extends InheritedWidget {
  const _GlassScope({required super.child});

  static bool isInside(BuildContext context) => context.getInheritedWidgetOfExactType<_GlassScope>() != null;

  @override
  bool updateShouldNotify(_GlassScope oldWidget) => false;
}

/// Bóng đổ chỉ vẽ ở PHÍA NGOÀI hình kính.
///
/// - Dùng RRect thay cho superellipse: Impeller trên Android vẽ bóng
///   `RoundedSuperellipseBorder` thành khối chữ nhật nhoè (lỗi ở các nút tròn).
/// - Cắt bỏ phần bên trong: kính trong suốt nên nếu không cắt, bóng phía
///   sau sẽ lộ qua làm lòng nút bị tối/bẩn.
class _OuterShadowPainter extends CustomPainter {
  final BorderRadius radius;
  final List<BoxShadow> shadows;
  final double scale;

  _OuterShadowPainter(this.radius, this.shadows, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    if (scale <= 0) return;
    final shape = radius.toRRect(Offset.zero & size);
    final bounds = (Offset.zero & size).inflate(200);
    canvas.saveLayer(bounds, Paint());
    for (final s in shadows) {
      final scaled = BoxShadow(
        color: s.color.withValues(alpha: (s.color.a * scale.clamp(0.0, 1.0))),
        blurRadius: s.blurRadius * scale,
        spreadRadius: s.spreadRadius * scale,
        offset: s.offset * scale,
      );
      canvas.drawRRect(shape.shift(scaled.offset).inflate(scaled.spreadRadius), scaled.toPaint());
    }
    // Xoá phần bóng nằm dưới kính với mép xoá mềm (thay cho clip cứng): mép
    // kính khúc xạ lấy mẫu cả vùng sát ngoài, nếu bóng bị cắt gắt thì vết cắt
    // đó bị kéo vào thành một đường viền tách rời phần lòng kính.
    canvas.drawRRect(
      shape.deflate(2),
      Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) => old.radius != radius || old.shadows != shadows || old.scale != scale;
}

/// Viền kính: sáng ở góc trên-trái, mờ dần ở giữa, ánh nhẹ ở góc dưới-phải
/// – mô phỏng ánh sáng khúc xạ trên mép kính.
class _GlassRimPainter extends CustomPainter {
  final BorderRadius radius;
  final Color highlight;
  final Color shade;

  _GlassRimPainter(this.radius, this.highlight, this.shade);

  @override
  void paint(Canvas canvas, Size size) {
    // Ánh bóng mặt kính: dải sáng mềm ở nửa trên, như mặt cong hắt sáng trời.
    final full = Offset.zero & size;
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            highlight.withValues(alpha: highlight.a * 0.08),
            highlight.withValues(alpha: 0),
          ],
          stops: const [0, 0.55],
        ).createShader(full),
    );
    final rect = (Offset.zero & size).deflate(0.6);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          highlight,
          shade,
          shade,
          highlight.withValues(alpha: highlight.a * 0.6),
        ],
        stops: const [0, 0.35, 0.7, 1],
      ).createShader(rect);
    canvas.drawPath(RoundedSuperellipseBorder(borderRadius: radius).getOuterPath(rect), paint);
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) => old.radius != radius || old.highlight != highlight || old.shade != shade;
}

/// Nền loang màu phía sau lớp kính, để kính có gì đó để "khúc xạ".
class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    return RepaintBoundary(
      child: CustomPaint(painter: _BlobPainter(g.backdropBase, g.backdropBlobs), child: const SizedBox.expand()),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color base;
  final List<Color> blobs;

  _BlobPainter(this.base, this.blobs);

  static const _spots = [
    (Offset(0.05, 0.02), 0.95),
    (Offset(1.0, 0.28), 0.8),
    (Offset(0.0, 0.72), 0.85),
    (Offset(0.95, 0.98), 0.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    for (var i = 0; i < _spots.length && i < blobs.length; i++) {
      final (pos, r) = _spots[i];
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final radius = r * size.width;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [blobs[i].withValues(alpha: 0.85), blobs[i].withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.base != base || old.blobs != blobs;
}

/// Scaffold có nền loang, AppBar kính và nội dung cuộn xuyên dưới AppBar.
/// Trong [body], dùng `MediaQuery.paddingOf(context).top` để chừa chỗ cho AppBar.
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: LiquidBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomBar,
        ),
      ],
    );
  }
}

/// AppBar kiểu iOS 26: thanh kính mờ, nút quay lại dạng viên kính tròn.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  /// Độ hiện của lớp kính nền (0 = trong suốt như iOS khi chưa cuộn).
  final double backgroundOpacity;

  const GlassAppBar({super.key, this.title, this.actions = const [], this.bottom, this.backgroundOpacity = 1});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final g = GlassTheme.of(context);
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: canPop
          ? Center(
              child: GlassIconButton(
                key: const Key('glass-back'),
                icon: CupertinoIcons.chevron_back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      title: title,
      actions: [
        for (final a in actions) Padding(padding: const EdgeInsets.only(right: 4), child: a),
        const SizedBox(width: 8),
      ],
      bottom: bottom,
      // SizedBox.expand: nếu không, lớp kính co về 0×0 và trên Impeller
      // BackdropFilter không làm mờ gì cả (thanh trong suốt, chữ đè lên nhau).
      flexibleSpace: _fade(
        SizedBox.expand(
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.compose(
                outer: ui.ImageFilter.blur(sigmaX: g.blurSigma, sigmaY: g.blurSigma, tileMode: TileMode.mirror),
                inner: _vibrancy,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      g.thickTint,
                      g.tint.withValues(alpha: g.tint.a * 0.6),
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: g.rimHighlight.withValues(alpha: 0.5), width: 0.5)),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _fade(Widget glass) {
    if (backgroundOpacity <= 0) return null;
    if (backgroundOpacity >= 1) return glass;
    return Opacity(opacity: backgroundOpacity, child: glass);
  }
}

/// Nút tròn bằng kính với icon đổi hình mượt (morph) và phản hồi lò xo.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? tint;
  final Color? iconColor;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.tint,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    Widget button = Pressable(
      onTap: onPressed,
      pressedScale: 0.86,
      semanticLabel: tooltip,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: AppMotion.short,
        child: GlassSurface(
          borderRadius: BorderRadius.circular(size / 2),
          tint: tint,
          shadow: enabled,
          shadowScale: 0.45,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: MorphSwitcher(
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  size: size * 0.48,
                  color: iconColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Nút dạng viên thuốc (pill) bằng kính. [prominent] = kính nhuộm màu chủ đạo.
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool prominent;
  final bool expand;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.prominent = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = prominent ? scheme.onPrimary : scheme.onSurface;
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
    return Pressable(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.45 : 1,
        duration: AppMotion.short,
        child: GlassSurface(
          borderRadius: BorderRadius.circular(100),
          tint: prominent ? scheme.primary.withValues(alpha: 0.88) : null,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          child: row,
        ),
      ),
    );
  }
}

/// Thẻ kính, có phản hồi lò xo khi [onTap] khác null.
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? tint;
  final bool thick;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTheme.radiusLarge)),
    this.tint,
    this.thick = false,
  });

  @override
  Widget build(BuildContext context) {
    final surface = GlassSurface(borderRadius: borderRadius, padding: padding, tint: tint, thick: thick, child: child);
    if (onTap == null) return surface;
    return Pressable(onTap: onTap, pressedScale: 0.96, child: surface);
  }
}

/// Màn hình tạm cho tính năng đang phát triển, theo phong cách kính.
class ComingSoonView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const ComingSoonView({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EntranceAnimation(
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CookieIcon(icon: icon, color: color, size: 88),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
