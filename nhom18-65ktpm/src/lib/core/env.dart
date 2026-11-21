/// Cấu hình truyền lúc chạy:
///   flutter run --dart-define-from-file=env.json
/// Không hardcode key vào code.
/// [supabaseAnonKey] nhận cả anon key cũ và publishable key mới của Supabase.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
