import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quản lý khởi tạo và kết nối CSDL trực tuyến Supabase (PostgreSQL + Realtime).
///
/// Chạy ứng dụng kèm file môi trường `.env`:
/// `flutter run -d chrome --dart-define-from-file=.env`
class SupabaseConfig {
  SupabaseConfig._();

  static const String _rawSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Tự chuẩn hóa URL gốc của Supabase (bỏ `/rest/v1/` nếu copy từ mục Data API)
  static String get supabaseUrl {
    var url = _rawSupabaseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - '/rest/v1'.length);
    }
    return url;
  }

  static bool _isInitialized = false;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isInitialized => _isInitialized;

  /// Khởi tạo kết nối Supabase trực tuyến từ biến môi trường `.env`
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isConfigured) {
      debugPrint(
        '[SupabaseConfig] Thiếu SUPABASE_URL hoặc SUPABASE_ANON_KEY trong .env. '
        'Hãy chạy với cờ --dart-define-from-file=.env để kết nối CSDL trực tuyến.',
      );
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    _isInitialized = true;
    debugPrint('[SupabaseConfig] Kết nối Supabase thành công: $supabaseUrl');
  }

  /// Trả về SupabaseClient bắt buộc đã kết nối (không trả dữ liệu giả lập)
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Chưa kết nối CSDL Supabase. Hãy kiểm tra file .env và chạy lại với '
        '--dart-define-from-file=.env.',
      );
    }
    return Supabase.instance.client;
  }
}
