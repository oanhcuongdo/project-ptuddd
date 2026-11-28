import '../../../core/supabase_client.dart';
import '../../../core/supabase_errors.dart';
import '../../../models/shop.dart';
import '../../../repositories/auth_repository.dart';

/// Dữ liệu do chủ tiệm được phép nhập. Không chứa owner_id, status hoặc rating.
class ShopDraft {
  const ShopDraft({
    required this.name,
    required this.category,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    this.imageUrl,
  });

  final String name;
  final String category;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final String? imageUrl;

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'category': category,
    'phone': phone.trim(),
    'address': address.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'open_time': openTime,
    'close_time': closeTime,
    'image_url': (imageUrl == null || imageUrl!.trim().isEmpty)
        ? null
        : imageUrl!.trim(),
  };
}

/// UC-09: chỉ đọc/tạo/sửa các tiệm thuộc tài khoản đang đăng nhập.
/// Supabase RLS vẫn là lớp kiểm tra quyền bắt buộc ở phía máy chủ.
class OwnerShopRepository {
  String get _ownerId {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AppException(
        'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    return user.id;
  }

  Future<List<Shop>> myShops() {
    return guardSupabase(() async {
      final rows = await supabase
          .from('shops')
          .select()
          .eq('owner_id', _ownerId)
          .order('created_at', ascending: false);
      return rows
          .map((row) => Shop.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  Future<Shop> create(ShopDraft draft) {
    return guardSupabase(() async {
      final row = await supabase
          .from('shops')
          .insert({
            ...draft.toMap(),
            'owner_id': _ownerId,
            'status': 'pending',
            'is_open': false,
          })
          .select()
          .single();
      return Shop.fromMap(Map<String, dynamic>.from(row));
    });
  }

  Future<Shop> update({required Shop shop, required ShopDraft draft}) {
    return guardSupabase(() async {
      if (shop.ownerId != _ownerId) {
        throw const AppException('Bạn không có quyền sửa tiệm này.');
      }
      if (shop.status == 'banned') {
        throw const AppException('Tiệm đã bị khóa. Liên hệ quản trị viên.');
      }
      final row = await supabase
          .from('shops')
          .update(draft.toMap())
          .eq('id', shop.id)
          .eq('owner_id', _ownerId)
          .select()
          .maybeSingle();
      if (row == null) {
        throw const AppException(
          'Không tìm thấy tiệm hoặc không có quyền cập nhật.',
        );
      }
      return Shop.fromMap(Map<String, dynamic>.from(row));
    });
  }
}
