import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quản lý khởi tạo và kết nối Supabase Cloud Database & Realtime WebSocket.
///
/// Truyền cấu hình bảo mật khi chạy ứng dụng bằng:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool _isInitialized = false;

  /// Kiểm tra cấu hình Supabase đã được cung cấp đầy đủ chưa
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Kiểm tra Supabase Client đã sẵn sàng dùng hay chưa
  static bool get isInitialized => _isInitialized;

  /// Khởi tạo Supabase an toàn (không làm crash app khi chạy chế độ Offline-First)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isConfigured) {
      debugPrint(
        '[SupabaseConfig] Chưa cấu hình SUPABASE_URL / SUPABASE_ANON_KEY. '
        'Ứng dụng sẽ chạy ở chế độ Offline-First (SQLite cục bộ).',
      );
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    _isInitialized = true;
    debugPrint('[SupabaseConfig] Kết nối Supabase Cloud thành công.');
  }

  /// Trả về SupabaseClient khi đã khởi tạo (trả về null nếu đang chạy Offline)
  static SupabaseClient? get clientOrNull =>
      _isInitialized ? Supabase.instance.client : null;
}
