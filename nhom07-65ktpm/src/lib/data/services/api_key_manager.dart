import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Quản lý khóa API Gemini an toàn (ApiKeyManager)
/// Lưu trữ khóa API tùy chỉnh của người dùng trong FlutterSecureStorage (mã hóa Keystore/Keychain).
/// Hỗ trợ fallback về biến môi trường GEMINI_API_KEY khi chưa cấu hình custom key.
class ApiKeyManager {
  static const String _storageKey = 'user_gemini_api_key';

  final FlutterSecureStorage _storage;

  ApiKeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Lấy khóa API hiện hành:
  /// 1. Ưu tiên khóa tùy chỉnh người dùng lưu trong FlutterSecureStorage.
  /// 2. Nếu không có, fallback về biến môi trường GEMINI_API_KEY.
  Future<String> getApiKey() async {
    try {
      final customKey = await _storage.read(key: _storageKey);
      if (customKey != null && customKey.trim().isNotEmpty) {
        return customKey.trim();
      }
    } catch (_) {
      // Trường hợp storage lỗi, tiếp tục fallback
    }

    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  /// Lưu khóa API do người dùng hoặc giảng viên nhập trực tiếp trên ứng dụng
  Future<void> saveCustomApiKey(String key) async {
    await _storage.write(key: _storageKey, value: key.trim());
  }

  /// Xóa khóa API tùy chỉnh khỏi bộ nhớ an toàn (khôi phục về môi trường mặc định)
  Future<void> clearCustomApiKey() async {
    await _storage.delete(key: _storageKey);
  }

  /// Kiểm tra xem người dùng đã lưu custom API key trong SecureStorage hay chưa
  Future<bool> hasCustomApiKey() async {
    try {
      final customKey = await _storage.read(key: _storageKey);
      return customKey != null && customKey.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra xem hệ thống có bất kỳ API key nào khả dụng (từ Storage hoặc Biến môi trường)
  Future<bool> hasAnyApiKey() async {
    final key = await getApiKey();
    return key.isNotEmpty;
  }
}
