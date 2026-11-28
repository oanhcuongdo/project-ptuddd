import '../models/sos_request.dart';

class SosContact {
  const SosContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Hợp đồng dùng chung cho UC-07 (gửi/hủy) và UC-12 (nhận/hoàn thành) do Tùng triển khai.
/// Nhận ca BẮT BUỘC đi qua RPC `accept_sos` để không 2 người nhận trùng.
abstract class SosRepository {
  Future<SosRequest> create({
    required String issueType,
    String? note,
    required String contactPhone,
    required double latitude,
    required double longitude,
  });

  /// Ca đang chờ trong bán kính, cập nhật realtime.
  Stream<List<SosRequest>> watchPending();

  /// Truyền đúng một trong [shopId] / [volunteerId].
  Future<SosRequest> accept({
    required String sosId,
    String? shopId,
    String? volunteerId,
  });

  Future<SosRequest> complete(String sosId);

  Future<void> cancel(String sosId);

  /// Tên + SĐT của bên đã nhận ca (dùng RPC `get_sos_contact`).
  Future<SosContact> contact(String sosId);
}
