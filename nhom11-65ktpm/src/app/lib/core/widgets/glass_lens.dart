import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shader khúc xạ cho Liquid Glass (chỉ chạy trên Impeller).
///
/// Nạp một lần lúc khởi động bằng [GlassLens.init]. Nếu thiết bị không hỗ trợ
/// (Skia, web, flutter_test) thì [GlassLens.available] = false và kính quay về
/// hiệu ứng làm mờ thông thường.
abstract final class GlassLens {
  static ui.FragmentProgram? _program;

  /// Tắt thủ công (vd. khi người dùng bật "Giảm độ trong suốt").
  static bool enabled = true;

  static bool get available => enabled && _program != null;

  static Future<void> init() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/glass_lens.frag');
    } catch (e) {
      debugPrint('GlassLens: không nạp được shader – dùng kính mờ thường ($e)');
    }
  }
}

/// Thông số quang học của mặt kính.
@immutable
class LensOptics {
  /// Độ dày mép khúc xạ (logical px).
  final double bezel;

  /// Độ lệch tối đa của nền ở sát mép (logical px).
  final double refraction;

  /// Tán sắc màu ở mép (0 = tắt).
  final double dispersion;

  /// Độ sáng viền phản chiếu.
  final double specular;

  const LensOptics({this.bezel = 22, this.refraction = 10, this.dispersion = 0.6, this.specular = 0.55});

  LensOptics copyWith({double? bezel, double? refraction, double? dispersion, double? specular}) => LensOptics(
    bezel: bezel ?? this.bezel,
    refraction: refraction ?? this.refraction,
    dispersion: dispersion ?? this.dispersion,
    specular: specular ?? this.specular,
  );

  @override
  bool operator ==(Object other) =>
      other is LensOptics &&
      other.bezel == bezel &&
      other.refraction == refraction &&
      other.dispersion == dispersion &&
      other.specular == specular;

  @override
  int get hashCode => Object.hash(bezel, refraction, dispersion, specular);
}

/// BackdropFilter khúc xạ: làm mờ + tăng bão hoà nền rồi bẻ cong nền ở mép kính.
///
/// Shader cần biết vị trí kính trên màn hình, nên lớp này vẽ lại khi cuộn
/// hoặc khi route chuyển cảnh (các thay đổi đó không tự gọi paint lại).
class LensBackdrop extends StatefulWidget {
  final Widget child;
  final double radius;
  final ui.ImageFilter baseFilter;
  final LensOptics optics;

  /// Hướng nguồn sáng (mặc định: từ trên-trái).
  final Offset light;

  const LensBackdrop({
    super.key,
    required this.child,
    required this.radius,
    required this.baseFilter,
    this.optics = const LensOptics(),
    this.light = const Offset(-0.55, -0.85),
  });

  @override
  State<LensBackdrop> createState() => _LensBackdropState();
}

class _LensBackdropState extends State<LensBackdrop> {
  final _listenables = <Listenable>[];
  final _key = GlobalKey();

  void _repaint() => (_key.currentContext?.findRenderObject())?.markNeedsPaint();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final l in _listenables) {
      l.removeListener(_repaint);
    }
    _listenables.clear();
    // Mọi vùng cuộn bao ngoài + animation của route.
    var ctx = context;
    while (true) {
      final s = Scrollable.maybeOf(ctx);
      if (s == null) break;
      _listenables.add(s.position);
      ctx = s.context;
    }
    final route = ModalRoute.of(context);
    if (route?.animation != null) _listenables.add(route!.animation!);
    if (route?.secondaryAnimation != null) _listenables.add(route!.secondaryAnimation!);
    for (final l in _listenables) {
      l.addListener(_repaint);
    }
  }

  @override
  void dispose() {
    for (final l in _listenables) {
      l.removeListener(_repaint);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LensBackdropFilter(
      key: _key,
      program: GlassLens._program!,
      radius: widget.radius,
      baseFilter: widget.baseFilter,
      optics: widget.optics,
      light: widget.light,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: widget.child,
    );
  }
}

class _LensBackdropFilter extends SingleChildRenderObjectWidget {
  final ui.FragmentProgram program;
  final double radius;
  final ui.ImageFilter baseFilter;
  final LensOptics optics;
  final Offset light;
  final double devicePixelRatio;

  const _LensBackdropFilter({
    super.key,
    required super.child,
    required this.program,
    required this.radius,
    required this.baseFilter,
    required this.optics,
    required this.light,
    required this.devicePixelRatio,
  });

  @override
  _RenderLensBackdrop createRenderObject(BuildContext context) => _RenderLensBackdrop()..update(this);

  @override
  void updateRenderObject(BuildContext context, _RenderLensBackdrop renderObject) => renderObject.update(this);
}

class _RenderLensBackdrop extends RenderProxyBox {
  late ui.FragmentProgram _program;
  late double _radius;
  late ui.ImageFilter _base;
  late LensOptics _optics;
  late Offset _light;
  late double _dpr;

  void update(_LensBackdropFilter w) {
    _program = w.program;
    _radius = w.radius;
    _base = w.baseFilter;
    _optics = w.optics;
    _light = w.light;
    _dpr = w.devicePixelRatio;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    // Vị trí kính trên màn hình (pixel thiết bị), đã tính cả phép biến đổi
    // của tổ tiên (scale khi nhấn, dịch khi cuộn...).
    final transform = getTransformTo(null);
    final logical = MatrixUtils.transformRect(transform, Offset.zero & size);
    final scale = size.width > 0 ? logical.width / size.width : 1.0;
    final rect = Rect.fromLTWH(logical.left * _dpr, logical.top * _dpr, logical.width * _dpr, logical.height * _dpr);
    final k = scale * _dpr;
    final shortest = rect.shortestSide;

    final shader = _program.fragmentShader();
    var i = 2; // 0,1 = u_size do engine gán.
    void f(double v) => shader.setFloat(i++, v);
    f(rect.left);
    f(rect.top);
    f(rect.width);
    f(rect.height);
    f(_radius * k);
    f((_optics.bezel * k).clamp(1.0, shortest / 2));
    f(_optics.refraction * k);
    f(_optics.dispersion);
    f(_light.dx);
    f(_light.dy);
    f(_optics.specular);
    f(1.2 * k);

    layer ??= BackdropFilterLayer();
    layer!.filter = ui.ImageFilter.compose(outer: ui.ImageFilter.shader(shader), inner: _base);
    context.pushLayer(layer!, super.paint, offset);
  }
}
