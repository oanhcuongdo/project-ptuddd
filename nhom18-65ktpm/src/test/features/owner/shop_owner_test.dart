import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/owner/data/owner_shop_repository.dart';
import 'package:ketnoitinhnguyenvienxemay/features/owner/data/shop_location_rules.dart';

void main() {
  group('UC-10: Kiểm tra tọa độ', () {
    test('Hà Nội hợp lệ', () {
      expect(ShopLocationRules.validateCoordinates(21.0285, 105.8542), isNull);
    });
    test('Tọa độ nước ngoài bị từ chối', () {
      expect(
        ShopLocationRules.validateCoordinates(35.6762, 139.6503),
        'Vị trí không nằm trong phạm vi phục vụ.',
      );
    });
    test('Thiếu hoặc sai tọa độ bị từ chối', () {
      expect(ShopLocationRules.validateCoordinates(null, 105.0), isNotNull);
      expect(ShopLocationRules.validateCoordinates(95, 105.0), isNotNull);
      expect(ShopLocationRules.validateCoordinates(double.nan, 105.0), isNotNull);
    });
  });

  group('UC-09: ShopDraft', () {
    test('Chuẩn hóa tên, hotline và URL ảnh', () {
      const draft = ShopDraft(
        name: '  Tiệm xe số 1  ', category: 'repair_shop',
        phone: ' 0912345678 ', address: '  Hà Nội  ',
        latitude: 21.0285, longitude: 105.8542,
        openTime: '07:00:00', closeTime: '21:00:00',
        imageUrl: ' ',
      );
      final data = draft.toMap();
      expect(data['name'], 'Tiệm xe số 1');
      expect(data['phone'], '0912345678');
      expect(data['address'], 'Hà Nội');
      expect(data['image_url'], isNull);
      expect(data.containsKey('owner_id'), isFalse);
      expect(data.containsKey('status'), isFalse);
    });
  });
}
