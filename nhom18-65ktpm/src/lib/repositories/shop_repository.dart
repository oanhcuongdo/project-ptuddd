import '../core/supabase_client.dart';
import '../models/shop.dart';

/// Đọc dữ liệu tiệm. Hiếu bổ sung phần CRUD của chủ tiệm (UC-09, UC-10).
class ShopRepository {
  /// UC-02/03: danh sách tiệm trong bán kính, gần nhất trước.
  Future<List<Shop>> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    String? category,
    bool openOnly = false,
  }) async {
    final rows = await supabase.rpc(
      'get_nearby_shops',
      params: {
        'p_lat': latitude,
        'p_lng': longitude,
        'p_radius_m': radiusMeters,
        'p_category': category,
        'p_open_only': openOnly,
      },
    );

    return (rows as List)
        .map((row) => Shop.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// UC-04: chi tiết một tiệm.
  Future<Shop?> byId(String id) async {
    final data =
        await supabase.from('shops').select().eq('id', id).maybeSingle();
    if (data == null) return null;

    return Shop.fromMap(Map<String, dynamic>.from(data));
  }
}
