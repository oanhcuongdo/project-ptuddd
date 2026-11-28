import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/models/review.dart';
import 'package:ketnoitinhnguyenvienxemay/models/shop.dart';
import 'package:ketnoitinhnguyenvienxemay/models/sos_request.dart';
import 'package:ketnoitinhnguyenvienxemay/models/user.dart';
import 'package:ketnoitinhnguyenvienxemay/models/volunteer_profile.dart';

void main() {
  test('UserModel.fromMap đọc đúng và nhận diện banned', () {
    final user = UserModel.fromMap({
      'id': 'u1',
      'full_name': 'Lục Văn Thuận',
      'email': 'thuan@test.local',
      'phone': '0912345678',
      'role': 'admin',
      'status': 'banned',
      'ban_reason': 'Vi phạm quy định cộng đồng',
      'created_at': '2026-01-02T03:04:05Z',
    });

    expect(user.fullName, 'Lục Văn Thuận');
    expect(user.role, 'admin');
    expect(user.isBanned, isTrue);
    expect(user.banReason, 'Vi phạm quy định cộng đồng');
    expect(user.createdAt, isNotNull);
  });

  test('Shop.fromMap đọc distance_m và owner_name từ RPC', () {
    final shop = Shop.fromMap({
      'id': 's1',
      'owner_id': 'u2',
      'owner_name': 'Nguyễn Văn A',
      'name': 'Sửa xe A',
      'category': 'repair_shop',
      'phone': '0900000000',
      'address': 'Hà Nội',
      'latitude': 21.02,
      'longitude': 105.85,
      'open_time': '07:00:00',
      'close_time': '21:00:00',
      'is_open': true,
      'rating': 4,
      'review_count': 2,
      'status': 'rejected',
      'rejection_reason': 'Địa chỉ chưa rõ ràng',
      'distance_m': 1234.5,
    });

    expect(shop.rating, 4.0);
    expect(shop.reviewCount, 2);
    expect(shop.distanceM, 1234.5);
    expect(shop.ownerName, 'Nguyễn Văn A');
    expect(shop.isOpen, isTrue);
    expect(shop.rejectionReason, 'Địa chỉ chưa rõ ràng');
  });

  test('SosRequest.fromMap mặc định status pending', () {
    final sos = SosRequest.fromMap({
      'id': 'sos1',
      'rider_id': 'u1',
      'issue_type': 'Thủng lốp',
      'contact_phone': '0912345678',
      'latitude': 21.0,
      'longitude': 105.8,
    });

    expect(sos.status, 'pending');
    expect(sos.isPending, isTrue);
    expect(sos.acceptedShopId, isNull);
  });

  test('VolunteerProfile.fromMap ép skills về List<String>', () {
    final profile = VolunteerProfile.fromMap({
      'id': 'v1',
      'user_id': 'u3',
      'phone': '0987000000',
      'skills': ['Vá xe', 'Kích bình'],
      'id_card_url': 'seed/cccd.jpg',
      'service_radius_km': 10,
      'is_available': true,
      'status': 'rejected',
      'rejection_reason': 'Ảnh giấy tờ bị mờ',
      'completed_count': 3,
    });

    expect(profile.skills, ['Vá xe', 'Kích bình']);
    expect(profile.serviceRadiusKm, 10);
    expect(profile.completedCount, 3);
    expect(profile.rejectionReason, 'Ảnh giấy tờ bị mờ');
  });

  test('Review.fromMap giữ rating, comment và rider_name', () {
    final review = Review.fromMap({
      'id': 'r1',
      'shop_id': 's1',
      'rider_id': 'u1',
      'rider_name': 'Trần Thị B',
      'rating': 5,
      'comment': 'Tốt',
    });

    expect(review.rating, 5);
    expect(review.comment, 'Tốt');
    expect(review.riderName, 'Trần Thị B');
  });
}
