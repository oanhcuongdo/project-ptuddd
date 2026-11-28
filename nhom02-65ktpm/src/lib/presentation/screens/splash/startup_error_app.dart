import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Hiển thị khi khởi tạo Firebase thất bại (thường do chưa chạy
/// `flutterfire configure`), thay vì để ứng dụng crash.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Không khởi động được Firebase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kiểm tra lại cấu hình: chạy "flutterfire configure" trong thư mục '
                  'src/ và đảm bảo có file android/app/google-services.json.',
                ),
                const SizedBox(height: 16),
                Text(
                  '$error',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
