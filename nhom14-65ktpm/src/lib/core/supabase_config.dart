import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quản lý cấu hình và khởi tạo Supabase Client dùng chung cho toàn bộ dự án.
/// Các thông số kết nối được nạp an toàn từ cấu hình build-time (--dart-define-from-file).
class SupabaseConfig {
  SupabaseConfig._();

  static const String _rawUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _rawAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// URL chuẩn hóa (loại bỏ dấu gạch chéo cuối và path con /rest/v1 nếu người dùng điền thừa)
  static String get supabaseUrl {
    var url = _rawUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - '/rest/v1'.length);
    }
    return url;
  }

  /// Publishable/Anon Key
  static String get supabaseAnonKey => _rawAnonKey.trim();

  /// Kiểm tra xem cấu hình biến môi trường đã được cung cấp đầy đủ chưa
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Cờ ghi nhận trạng thái khởi tạo thành công
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Khởi tạo Supabase đúng một lần duy nhất trước khi gọi runApp()
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isConfigured) {
      debugPrint(
        '⚠️ [SupabaseConfig] CẢNH BÁO: Chưa tìm thấy SUPABASE_URL hoặc SUPABASE_ANON_KEY.\n'
        'Ứng dụng vẫn có thể chạy giao diện, nhưng các tính năng Backend sẽ không hoạt động.\n'
        'Cách khắc phục: Khởi chạy ứng dụng với cờ:\n'
        '  flutter run --dart-define-from-file=env.json',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('✅ [SupabaseConfig] Đã khởi tạo Supabase Client thành công.');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupabaseConfig] Lỗi khi khởi tạo Supabase: $e');
      debugPrint('$stackTrace');
    }
  }

  /// Getter cung cấp Supabase Client dùng chung
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase chưa được khởi tạo thành công. Vui lòng kiểm tra file env.json và gọi SupabaseConfig.initialize() trước khi sử dụng.',
      );
    }
    return Supabase.instance.client;
  }

  /// Phương thức kiểm tra kết nối tới Supabase Backend
  static Future<Map<String, dynamic>> checkConnection() async {
    if (!_isInitialized) {
      return {
        'connected': false,
        'message': 'Supabase Client chưa được khởi tạo (thiếu SUPABASE_URL hoặc SUPABASE_ANON_KEY).',
      };
    }

    try {
      // Gửi truy vấn kiểm tra tới bảng profiles
      await client.from('profiles').select('id').limit(1);
      return {
        'connected': true,
        'message': 'Kết nối Supabase và bảng profiles hoạt động bình thường.',
      };
    } on PostgrestException catch (e) {
      // Mã 42P01 hoặc PGRST205: bảng public.profiles chưa tồn tại trong schema
      if (e.code == '42P01' || e.code == 'PGRST205') {
        return {
          'connected': true,
          'needs_migration': true,
          'message':
              'Đã kết nối thành công tới máy chủ Supabase! Bảng "profiles" chưa được tạo trên CSDL (hãy chạy file migration SQL trên Supabase Dashboard).',
        };
      }
      // Mã 42501: permission denied - bảng profiles đã tồn tại và RLS đang chặn truy cập trái phép của người dùng chưa đăng nhập
      if (e.code == '42501') {
        return {
          'connected': true,
          'message':
              'Đã kết nối máy chủ Supabase thành công! Bảng profiles và bảo mật RLS đang hoạt động chuẩn xác.',
        };
      }
      return {
        'connected': false,
        'error_code': e.code,
        'message': 'Lỗi truy vấn Supabase: ${e.message}',
      };
    } catch (e) {
      return {
        'connected': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
}

/// Getter tiện ích truy cập nhanh Supabase Client từ bất kỳ file nào
SupabaseClient get supabase => SupabaseConfig.client;
