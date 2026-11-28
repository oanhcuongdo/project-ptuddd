import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router_preview.dart';

/// Entry point chạy thử toàn bộ giao diện mẫu (chưa cần cấu hình Firebase).
/// Bạn có thể chạy bằng lệnh: flutter run -t lib/main_ui_preview.dart
/// Hoặc gọi TravelBuddyApp() bên trong lib/main.dart sau khi Firebase.initializeApp().
void main() {
  runApp(
    const ProviderScope(
      child: TravelBuddyApp(),
    ),
  );
}

class TravelBuddyApp extends StatelessWidget {
  const TravelBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Travel Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouterPreview,
    );
  }
}
