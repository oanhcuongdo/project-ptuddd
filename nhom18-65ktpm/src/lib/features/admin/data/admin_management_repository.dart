import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../../core/supabase_errors.dart';
import '../../../models/shop.dart';
import '../../../models/user.dart';
import '../../../models/volunteer_profile.dart';
import '../../../repositories/auth_repository.dart';

class AdminManagementSnapshot {
  const AdminManagementSnapshot({
    required this.users,
    required this.shops,
    required this.volunteers,
  });

  final List<UserModel> users;
  final List<Shop> shops;
  final List<VolunteerProfile> volunteers;
}

class AdminManagementRepository {
  Future<String> _requireAdmin() async {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const AppException('Bạn cần đăng nhập.');
    }
    final profile = await supabase
        .from('users')
        .select('role,status')
        .eq('id', id)
        .maybeSingle();
    if (profile == null ||
        profile['role'] != 'admin' ||
        profile['status'] != 'active') {
      throw const AppException('Bạn không có quyền thực hiện thao tác này.');
    }
    return id;
  }

  Future<AdminManagementSnapshot> load() {
    return guardSupabase(() async {
      await _requireAdmin();
      final results = await Future.wait<List<Map<String, dynamic>>>([
        supabase.from('users').select().order('created_at', ascending: false),
        supabase.from('shops').select().order('created_at', ascending: false),
        supabase
            .from('volunteer_profiles')
            .select()
            .order('created_at', ascending: false),
      ]);

      return AdminManagementSnapshot(
        users: results[0]
            .map((row) => UserModel.fromMap(Map<String, dynamic>.from(row)))
            .toList(),
        shops: results[1]
            .map((row) => Shop.fromMap(Map<String, dynamic>.from(row)))
            .toList(),
        volunteers: results[2]
            .map(
              (row) =>
                  VolunteerProfile.fromMap(Map<String, dynamic>.from(row)),
            )
            .toList(),
      );
    });
  }

  Future<void> changeUserStatus(
    UserModel user,
    String nextStatus, {
    String? reason,
  }) {
    return guardSupabase(() async {
      final adminId = await _requireAdmin();
      if (nextStatus != 'active' && nextStatus != 'banned') {
        throw const AppException('Trạng thái tài khoản không hợp lệ.');
      }
      if (user.id == adminId || user.role == 'admin') {
        throw const AppException('Không được thay đổi tài khoản quản trị.');
      }
      final trimmedReason = nextStatus == 'banned' ? reason?.trim() : null;
      // RPC đồng bộ khóa/mở khóa users + shops + volunteer_profiles và trả ca SOS accepted về pending.
      // Hỗ trợ fallback về chữ ký RPC 2 tham số nếu Supabase chưa chạy bản 03_functions.sql mới.
      try {
        await supabase.rpc(
          'admin_set_user_status',
          params: {
            'p_user_id': user.id,
            'p_status': nextStatus,
            'p_reason': trimmedReason,
          },
        );
      } on PostgrestException catch (e) {
        if (e.code != 'PGRST202' &&
            !e.message.contains('admin_set_user_status')) {
          rethrow;
        }
        await supabase.rpc(
          'admin_set_user_status',
          params: {'p_user_id': user.id, 'p_status': nextStatus},
        );
      }
    });
  }

  Future<void> changeShopStatus(
    Shop shop,
    String nextStatus, {
    String? rejectionReason,
  }) {
    return guardSupabase(() async {
      await _requireAdmin();
      const valid = {'pending', 'approved', 'rejected', 'banned'};
      if (!valid.contains(nextStatus)) {
        throw const AppException('Trạng thái tiệm không hợp lệ.');
      }
      final changes = <String, dynamic>{
        'status': nextStatus,
        'rejection_reason': nextStatus == 'rejected'
            ? rejectionReason?.trim()
            : null,
      };
      if (nextStatus != 'approved') {
        changes['is_open'] = false;
      }
      final updated = await supabase
          .from('shops')
          .update(changes)
          .eq('id', shop.id)
          .select('id')
          .maybeSingle();
      if (updated == null) {
        throw const AppException('Không thể cập nhật tiệm.');
      }
    });
  }

  Future<void> changeVolunteerStatus(
    VolunteerProfile volunteer,
    String nextStatus, {
    String? rejectionReason,
  }) {
    return guardSupabase(() async {
      await _requireAdmin();
      const valid = {'pending', 'approved', 'rejected', 'banned'};
      if (!valid.contains(nextStatus)) {
        throw const AppException('Trạng thái tình nguyện viên không hợp lệ.');
      }
      final changes = <String, dynamic>{
        'status': nextStatus,
        'rejection_reason': nextStatus == 'rejected'
            ? rejectionReason?.trim()
            : null,
      };
      if (nextStatus != 'approved') {
        changes['is_available'] = false;
      }
      final updated = await supabase
          .from('volunteer_profiles')
          .update(changes)
          .eq('id', volunteer.id)
          .select('id')
          .maybeSingle();
      if (updated == null) {
        throw const AppException('Không thể cập nhật hồ sơ tình nguyện viên.');
      }
    });
  }

  Future<String> idCardSignedUrl(VolunteerProfile volunteer) async {
    await _requireAdmin();
    final raw = volunteer.idCardUrl.trim();
    if (raw.isEmpty) {
      throw const AppException('Hồ sơ chưa có giấy tờ xác minh.');
    }
    if (raw.startsWith('https://') || raw.startsWith('http://')) {
      throw const AppException(
        'Đường dẫn giấy tờ không phải đường dẫn nội bộ trong bucket id-cards.',
      );
    }
    final path = raw.startsWith('id-cards/')
        ? raw.substring('id-cards/'.length)
        : raw;
    return supabase.storage.from('id-cards').createSignedUrl(path, 300);
  }
}
