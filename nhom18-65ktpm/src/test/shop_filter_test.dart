import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/models/shop.dart';

void main() {
  group('Shop Filter Logic - UC-03', () {
    final sampleShops = [
      const Shop(
        id: '1',
        ownerId: 'owner-1',
        name: 'Tiệm Sửa Xe Honda Phát Đạt',
        category: 'repair_shop',
        phone: '0912345678',
        address: '123 Giải Phóng, Hai Bà Trưng, Hà Nội',
        latitude: 21.0000,
        longitude: 105.8400,
        openTime: '07:00:00',
        closeTime: '21:00:00',
        isOpen: true,
        rating: 4.8,
        reviewCount: 25,
        status: 'approved',
        distanceM: 350,
      ),
      const Shop(
        id: '2',
        ownerId: 'owner-2',
        name: 'Cây Xăng Petrolimex Số 15',
        category: 'gas_station',
        phone: '02438581234',
        address: '456 Trường Chinh, Đống Đa, Hà Nội',
        latitude: 21.0050,
        longitude: 105.8300,
        openTime: '06:00:00',
        closeTime: '23:00:00',
        isOpen: false,
        rating: 4.2,
        reviewCount: 10,
        status: 'approved',
        distanceM: 1200,
      ),
      const Shop(
        id: '3',
        ownerId: 'owner-3',
        name: 'Cứu Hộ Vá Xe Đêm 24/7',
        category: 'repair_shop',
        phone: '0987654321',
        address: '789 Đại Cồ Việt, Hai Bà Trưng, Hà Nội',
        latitude: 21.0100,
        longitude: 105.8450,
        openTime: '00:00:00',
        closeTime: '23:59:00',
        isOpen: true,
        rating: 5.0,
        reviewCount: 40,
        status: 'approved',
        distanceM: 2800,
      ),
    ];

    test('Lọc theo từ khóa tìm kiếm tên tiệm hoặc địa chỉ', () {
      final query = 'Honda'.toLowerCase();
      final filtered = sampleShops.where((s) =>
          s.name.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query)).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('Lọc theo danh mục tiệm sửa xe hoặc cây xăng', () {
      final repairOnly = sampleShops.where((s) => s.category == 'repair_shop').toList();
      expect(repairOnly.length, 2);

      final gasOnly = sampleShops.where((s) => s.category == 'gas_station').toList();
      expect(gasOnly.length, 1);
      expect(gasOnly.first.id, '2');
    });

    test('Lọc theo trạng thái chỉ tiệm đang mở cửa', () {
      final openOnly = sampleShops.where((s) => s.isOpen).toList();
      expect(openOnly.length, 2);
      expect(openOnly.any((s) => s.id == '2'), isFalse);
    });
  });
}
