import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../../core/supabase_errors.dart';
import '../../../models/sos_request.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/sos_repository.dart';

/// Một ca trong hộp thư người nhận (RPC `get_my_pending_sos`).
class NearbySos {
  const NearbySos({
    required this.request,
    required this.distanceM,
    this.shopId,
    this.volunteerId,
  });

  final SosRequest request;
  final double distanceM;

  /// Đúng một trong hai khác null, truyền thẳng vào [SosRepository.accept].
  final String? shopId;
  final String? volunteerId;

  factory NearbySos.fromMap(Map<String, dynamic> map) {
    return NearbySos(
      request: SosRequest.fromMap(map),
      distanceM: (map['distance_m'] as num?)?.toDouble() ?? 0,
      shopId: map['shop_id']?.toString(),
      volunteerId: map['volunteer_id']?.toString(),
    );
  }
}

class SupabaseSosRepository implements SosRepository {
  /// Realtime không báo cho người không còn quyền đọc ca (ca vừa được người khác
  /// nhận hoặc bị hủy), nên hộp thư tải lại định kỳ để ca đó tự biến mất.
  static const inboxRefreshInterval = Duration(seconds: 10);

  String get _uid {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(
        'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.',
      );
    }
    return id;
  }

  // ===== UC-07: phía rider =====

  @override
  Future<SosRequest> create({
    required String issueType,
    String? note,
    required String contactPhone,
    required double latitude,
    required double longitude,
  }) {
    return guardSupabase(() async {
      final trimmedNote = note?.trim() ?? '';
      final row = await supabase
          .from('sos_requests')
          .insert({
            'rider_id': _uid,
            'issue_type': issueType,
            'note': trimmedNote.isEmpty ? null : trimmedNote,
            'contact_phone': contactPhone.replaceAll(' ', ''),
            'latitude': latitude,
            'longitude': longitude,
          })
          .select()
          .single();
      return SosRequest.fromMap(row);
    });
  }

  /// Ca đang chờ / đang được xử lý của rider, để mở lại màn hình theo dõi.
  Future<SosRequest?> myActiveRequest() {
    return guardSupabase(() async {
      final row = await supabase
          .from('sos_requests')
          .select()
          .eq('rider_id', _uid)
          .inFilter('status', ['pending', 'accepted'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : SosRequest.fromMap(row);
    });
  }

  @override
  Future<void> cancel(String sosId) {
    return guardSupabase(() async {
      final rows = await supabase
          .from('sos_requests')
          .update({'status': 'cancelled'})
          .eq('id', sosId)
          .eq('status', 'pending')
          .select('id');
      if (rows.isEmpty) {
        throw const AppException(
          'Ca cứu hộ đã có người tiếp nhận, không thể hủy.',
        );
      }
    });
  }

  @override
  Future<SosContact> contact(String sosId) {
    return guardSupabase(() async {
      final rows = await supabase.rpc(
        'get_sos_contact',
        params: {'p_sos_id': sosId},
      ) as List;
      if (rows.isEmpty) {
        throw const AppException('Chưa có người tiếp nhận ca này.');
      }
      final row = Map<String, dynamic>.from(rows.first as Map);
      return SosContact(
        name: row['provider_name']?.toString() ?? '',
        phone: row['provider_phone']?.toString() ?? '',
      );
    });
  }

  /// UC-07 E1: số tiệm / TNV đang được báo cho ca của rider (0 = không có ai quanh đó).
  Future<int> countHelpers(String sosId) {
    return guardSupabase(() async {
      final count = await supabase.rpc(
        'count_sos_helpers',
        params: {'p_sos_id': sosId},
      );
      return (count as num?)?.toInt() ?? 0;
    });
  }

  /// Theo dõi realtime một ca (rider xem ca của mình, người nhận xem ca đang xử lý).
  /// Phát null nếu không còn đọc được ca.
  Stream<SosRequest?> watchById(String sosId) {
    return supabase
        .from('sos_requests')
        .stream(primaryKey: ['id'])
        .eq('id', sosId)
        .map((rows) => rows.isEmpty ? null : SosRequest.fromMap(rows.first));
  }

  // ===== UC-12: phía người nhận =====

  /// Ca đang chờ mà người dùng hiện tại được phép nhận, gần nhất trước.
  Future<List<NearbySos>> nearbyPending() {
    return guardSupabase(() async {
      final rows = await supabase.rpc('get_my_pending_sos') as List;
      return rows
          .map(
            (row) => NearbySos.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    });
  }

  /// Hộp thư cập nhật realtime + tải lại định kỳ.
  Stream<List<NearbySos>> watchNearbyPending() {
    late final StreamController<List<NearbySos>> controller;
    RealtimeChannel? channel;
    Timer? timer;
    var loading = false;
    var reloadQueued = false;

    Future<void> refresh() async {
      if (loading) {
        reloadQueued = true;
        return;
      }
      loading = true;
      try {
        final list = await nearbyPending();
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      } finally {
        loading = false;
        if (reloadQueued && !controller.isClosed) {
          reloadQueued = false;
          unawaited(refresh());
        }
      }
    }

    controller = StreamController<List<NearbySos>>(
      onListen: () {
        unawaited(refresh());
        channel = supabase
            .channel('sos-inbox-${DateTime.now().microsecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'sos_requests',
              callback: (_) => unawaited(refresh()),
            )
            .subscribe();
        timer = Timer.periodic(
          inboxRefreshInterval,
          (_) => unawaited(refresh()),
        );
      },
      onCancel: () async {
        timer?.cancel();
        final current = channel;
        if (current != null) await supabase.removeChannel(current);
        await controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<SosRequest>> watchPending() {
    return watchNearbyPending().map(
      (list) => list.map((item) => item.request).toList(),
    );
  }

  /// Ca mà người dùng hiện tại đã tiếp nhận và chưa hoàn thành.
  Future<SosRequest?> myAcceptedCase() {
    return guardSupabase(() async {
      // RLS chỉ trả ca accepted mà tiệm / hồ sơ TNV của mình đã nhận.
      final row = await supabase
          .from('sos_requests')
          .select()
          .eq('status', 'accepted')
          .neq('rider_id', _uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : SosRequest.fromMap(row);
    });
  }

  @override
  Future<SosRequest> accept({
    required String sosId,
    String? shopId,
    String? volunteerId,
  }) {
    if ((shopId == null) == (volunteerId == null)) {
      throw ArgumentError('Truyền đúng một trong shopId hoặc volunteerId');
    }
    return guardSupabase(() async {
      final row = await supabase.rpc(
        'accept_sos',
        params: {
          'p_sos_id': sosId,
          'p_shop_id': shopId,
          'p_volunteer_id': volunteerId,
        },
      );
      return SosRequest.fromMap(Map<String, dynamic>.from(row as Map));
    });
  }

  @override
  Future<SosRequest> complete(String sosId) {
    return guardSupabase(() async {
      final row = await supabase.rpc(
        'complete_sos',
        params: {'p_sos_id': sosId},
      );
      return SosRequest.fromMap(Map<String, dynamic>.from(row as Map));
    });
  }
}
