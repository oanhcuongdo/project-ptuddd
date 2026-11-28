import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/sos/data/supabase_sos_repository.dart';
import 'package:ketnoitinhnguyenvienxemay/features/sos/sos_rules.dart';

void main() {
  test('sosIssueTypes khớp CHECK issue_type của bảng sos_requests', () {
    expect(sosIssueTypes, ['Hết xăng', 'Thủng lốp', 'Hỏng động cơ', 'Khác']);
  });

  test('validateSosNote giới hạn 300 ký tự', () {
    expect(validateSosNote(null), isNull);
    expect(validateSosNote('a' * 300), isNull);
    expect(validateSosNote('a' * 301), isNotNull);
  });

  test('formatDistance đổi m sang km từ 1000 m', () {
    expect(formatDistance(850.4), '850 m');
    expect(formatDistance(1250), '1.3 km');
  });

  test('formatAgo hiển thị thời gian tương đối', () {
    final now = DateTime(2026, 1, 1, 12);
    expect(
      formatAgo(now.subtract(const Duration(seconds: 20)), now: now),
      'vừa xong',
    );
    expect(
      formatAgo(now.subtract(const Duration(minutes: 5)), now: now),
      '5 phút trước',
    );
    expect(
      formatAgo(now.subtract(const Duration(hours: 3)), now: now),
      '3 giờ trước',
    );
    expect(formatAgo(null), '');
  });

  test('directionsUri tạo link chỉ đường Google Maps', () {
    final uri = directionsUri(21.0285, 105.8542);
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['destination'], '21.0285,105.8542');
    expect(uri.queryParameters['api'], '1');
  });

  test('NearbySos.fromMap đọc ca và bên nhận từ RPC get_my_pending_sos', () {
    final item = NearbySos.fromMap({
      'id': 'sos1',
      'rider_id': 'u1',
      'issue_type': 'Thủng lốp',
      'contact_phone': '0912345678',
      'latitude': 21.0,
      'longitude': 105.8,
      'status': 'pending',
      'distance_m': 420.5,
      'shop_id': null,
      'volunteer_id': 'v1',
    });

    expect(item.request.issueType, 'Thủng lốp');
    expect(item.distanceM, 420.5);
    expect(item.shopId, isNull);
    expect(item.volunteerId, 'v1');
  });
}
