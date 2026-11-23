import 'package:flutter/material.dart';

import 'route_helper.dart';

typedef FeatureRouteGenerator = Route<dynamic>? Function(RouteSettings settings);

/// Bộ điều hướng tổng (App Router) — không cần sửa file này khi thêm phân hệ mới.
class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';

  static final List<FeatureRouteGenerator> _generators = [];

  /// Đăng ký thêm router con cho từng phân hệ
  static void register(FeatureRouteGenerator generator) {
    if (!_generators.contains(generator)) {
      _generators.add(generator);
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    for (final generator in _generators) {
      final route = generator(settings);
      if (route != null) return route;
    }

    if (settings.name == initialRoute) {
      return RouteHelper.pendingPage(settings, 'BuddyTalk');
    }

    return RouteHelper.buildPage(
      settings,
      Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy trang')),
        body: Center(
          child: Text('Đường dẫn không tồn tại: ${settings.name}'),
        ),
      ),
    );
  }
}
