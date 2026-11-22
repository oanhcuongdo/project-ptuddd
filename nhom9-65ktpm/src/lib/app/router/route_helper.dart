import 'package:flutter/material.dart';

/// Tiện ích tạo Route dùng chung cho toàn bộ các file route con
class RouteHelper {
  RouteHelper._();

  static MaterialPageRoute<void> buildPage(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => page,
    );
  }

  /// Màn hình chờ tạm thời cho các route chưa gắn UI thật
  static MaterialPageRoute<void> pendingPage(
    RouteSettings settings,
    String title,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Text('Route ${settings.name} — Đang phát triển'),
        ),
      ),
    );
  }
}
