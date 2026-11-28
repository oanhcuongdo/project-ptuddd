import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/player_profile_model.dart';

/// Dịch vụ quản lý Hồ sơ Cầu thủ và Tải ảnh lên Supabase Storage
class ProfileService {
  final SupabaseClient _client;

  ProfileService({SupabaseClient? client}) : _client = client ?? supabase;

  /// 1. Tải thông tin hồ sơ cầu thủ theo User ID
  Future<PlayerProfileModel?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('player_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return PlayerProfileModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// 2. Lưu hoặc Cập nhật hồ sơ cầu thủ (Upsert vào bảng player_profiles)
  Future<PlayerProfileModel> saveProfile(PlayerProfileModel profile) async {
    try {
      await _client.from('player_profiles').upsert(profile.toJson());
      return profile;
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Tải ảnh đại diện lên Supabase Storage bucket 'avatars'
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    try {
      final ext = fileExtension.replaceAll('.', '').toLowerCase();
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      // Upload file nhị phân lên bucket 'avatars'
      await _client.storage.from('avatars').uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      // Lấy đường link URL công khai của ảnh
      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Kiểm tra sức khỏe kết nối CSDL (Health check)
  Future<bool> checkConnection() async {
    try {
      await _client.from('player_profiles').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }
}
