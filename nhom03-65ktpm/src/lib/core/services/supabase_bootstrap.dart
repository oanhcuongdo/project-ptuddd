import 'package:supabase_flutter/supabase_flutter.dart';

/// Khởi tạo Supabase cho phần dữ liệu dùng chung (bảng `notes`…).
///
/// Cấu hình đọc từ `--dart-define`, **không** nhúng khoá vào mã nguồn:
///
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<anon key>
/// ```
///
/// Chỉ dùng anon (publishable) key; **không** bao giờ nhúng khoá quản trị
/// cấp server vào app.
/// Khi thiếu biến, app vẫn chạy bình thường ở chế độ chỉ lưu trên máy
/// ([isConfigured] = false) — đây là lý do màn hình không crash khi clone repo.
///
/// Xác thực: Supabase nhận JWT của Firebase qua [accessToken] (Third-party auth
/// → Firebase). Vì vậy mọi request và cả Realtime đều chạy dưới `role` của
/// người dùng và chịu RLS (`user_id = auth.jwt() ->> 'sub'`).
abstract final class SupabaseBootstrap {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static SupabaseClient? _client;

  /// Client dùng chung; `null` khi chưa cấu hình hoặc chưa khởi tạo.
  static SupabaseClient? get client => _client;

  /// Gọi một lần trong `main.dart`, sau khi Firebase đã khởi tạo.
  ///
  /// [accessToken] nên trả về ID token Firebase mới nhất; Supabase dùng nó cho
  /// REST và Realtime. Trả về `null` nếu không cấu hình.
  static Future<SupabaseClient?> initialize({
    Future<String?> Function()? accessToken,
  }) async {
    if (!isConfigured) {
      return null;
    }
    final existing = _client;
    if (existing != null) {
      return existing;
    }
    final supabase = await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      accessToken: accessToken,
    );
    _client = supabase.client;
    return _client;
  }

  /// Chỉ dùng trong test: gán client dựng sẵn (không gọi `Supabase.initialize`).
  static void debugSetClient(SupabaseClient? client) {
    _client = client;
  }

  static Future<void> dispose() async {
    await _client?.dispose();
    _client = null;
  }
}
