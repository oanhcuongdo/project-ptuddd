import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';
import 'models/user_profile.dart';

/// Đăng nhập / đăng xuất / người dùng hiện tại. API thật đã có (#6).
/// Chủ sở hữu màn hình: **Đệ** (#24): chỉ cần dựng UI và gọi các hàm ở đây.
class AuthRepository {
  final ApiClient _api;
  final SecureStorageService _storage;

  AuthRepository(this._api, this._storage);

  Future<UserProfile> login(String email, String password) async {
    final json = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password, 'device_name': 'ChaiLish app'},
      requireAuth: false,
    );
    return _saveSession(json as Map<String, dynamic>);
  }

  Future<UserProfile> register({required String email, required String password, required String fullName}) async {
    final json = await _api.post(
      '/auth/register',
      body: {'email': email, 'password': password, 'full_name': fullName, 'device_name': 'ChaiLish app'},
      requireAuth: false,
    );
    return _saveSession(json as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh != null) {
      try {
        await _api.post('/auth/logout', body: {'refresh_token': refresh});
      } catch (_) {
        // Server không gọi được vẫn xoá phiên trên máy.
      }
    }
    await _storage.clearAuth();
  }

  /// Người dùng của token đang lưu; null nếu chưa đăng nhập / phiên hết hạn.
  Future<UserProfile?> currentUser() async {
    if ((await _storage.getToken()) == null) return null;
    try {
      return UserProfile.fromJson(await _api.get('/me') as Map<String, dynamic>);
    } on UnauthorizedException {
      await _storage.clearAuth();
      return null;
    }
  }

  Future<UserProfile> _saveSession(Map<String, dynamic> json) async {
    await _storage.saveToken(json['access_token'] as String);
    await _storage.saveRefreshToken(json['refresh_token'] as String);
    final user = UserProfile.fromJson(json['user'] as Map<String, dynamic>);
    await _storage.saveUserId(user.id);
    return user;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(secureStorageProvider)),
);

/// Người dùng hiện tại. Sau khi đăng nhập/đăng xuất gọi `ref.invalidate(currentUserProvider)`.
final currentUserProvider = FutureProvider<UserProfile?>((ref) => ref.watch(authRepositoryProvider).currentUser());
