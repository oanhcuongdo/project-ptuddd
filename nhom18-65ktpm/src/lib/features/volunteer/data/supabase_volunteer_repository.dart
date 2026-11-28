import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../../core/supabase_errors.dart';
import '../../../models/volunteer_profile.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/volunteer_repository.dart';
import '../volunteer_rules.dart';

/// UC-13 + UC-11 (phần TNV).
/// status / completed_count do trigger `protect_volunteer_columns` quản lý:
/// đổi SĐT hoặc giấy tờ khi đã duyệt thì hồ sơ tự về pending.
class SupabaseVolunteerRepository implements VolunteerRepository {
  static const _bucket = 'id-cards';

  String get _uid {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(
        'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.',
      );
    }
    return id;
  }

  @override
  Future<VolunteerProfile?> myProfile() {
    return guardSupabase(() async {
      final row = await supabase
          .from('volunteer_profiles')
          .select()
          .eq('user_id', _uid)
          .maybeSingle();
      return row == null ? null : VolunteerProfile.fromMap(row);
    });
  }

  @override
  Future<VolunteerProfile> saveProfile({
    required String phone,
    required List<String> skills,
    String? tools,
    required String idCardUrl,
    required int serviceRadiusKm,
  }) {
    final error =
        validateSkills(skills) ??
        validateRadius(serviceRadiusKm) ??
        validateTools(tools);
    if (error != null) throw AppException(error);
    if (idCardUrl.isEmpty) {
      throw const AppException('Vui lòng tải ảnh giấy tờ xác minh');
    }

    return guardSupabase(() async {
      final trimmedTools = tools?.trim() ?? '';
      final fields = {
        'phone': phone.replaceAll(' ', ''),
        'skills': skills,
        'tools': trimmedTools.isEmpty ? null : trimmedTools,
        'id_card_url': idCardUrl,
        'service_radius_km': serviceRadiusKm,
      };

      final existing = await myProfile();
      final row = existing == null
          // Hồ sơ mới: status = pending, is_available = false theo mặc định của bảng.
          ? await supabase
                .from('volunteer_profiles')
                .insert({...fields, 'user_id': _uid})
                .select()
                .single()
          : await supabase
                .from('volunteer_profiles')
                .update(fields)
                .eq('id', existing.id)
                .select()
                .single();
      return VolunteerProfile.fromMap(row);
    });
  }

  @override
  Future<void> setAvailable(bool value) {
    return guardSupabase(() async {
      final row = await supabase
          .from('volunteer_profiles')
          .update({'is_available': value})
          .eq('user_id', _uid)
          .select()
          .single();
      // Trigger ép về false khi hồ sơ chưa duyệt / bị khóa.
      if (VolunteerProfile.fromMap(row).isAvailable != value) {
        throw const AppException(
          'Hồ sơ chưa được duyệt nên chưa thể bật trạng thái sẵn sàng.',
        );
      }
    });
  }

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) {
    return guardSupabase(() async {
      await supabase
          .from('volunteer_profiles')
          .update({
            'location': ewktPoint(latitude: latitude, longitude: longitude),
          })
          .eq('user_id', _uid);
    });
  }

  /// Tải ảnh giấy tờ vào bucket riêng tư, trả về đường dẫn lưu ở `id_card_url`.
  Future<String> uploadIdCard({
    required Uint8List bytes,
    required String fileName,
  }) {
    final error = validateIdCard(fileName: fileName, sizeBytes: bytes.length);
    if (error != null) throw AppException(error);

    return guardSupabase(() async {
      final ext = fileName
          .substring(fileName.lastIndexOf('.') + 1)
          .toLowerCase();
      // Quy ước 04_storage.sql: <user_id>/<ten_file>.
      final path = '$_uid/cccd-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: idCardContentType(fileName)),
          );
      return path;
    });
  }

  /// Xóa ảnh cũ sau khi đã thay ảnh mới; lỗi không ảnh hưởng hồ sơ.
  Future<void> removeIdCard(String path) async {
    if (!path.startsWith('$_uid/')) return;
    try {
      await supabase.storage.from(_bucket).remove([path]);
    } catch (_) {}
  }

  /// Link xem ảnh giấy tờ trong 10 phút (bucket không công khai).
  Future<String> idCardViewUrl(String path) {
    return guardSupabase(
      () => supabase.storage.from(_bucket).createSignedUrl(path, 600),
    );
  }
}
