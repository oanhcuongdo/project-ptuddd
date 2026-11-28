import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/shop/widgets/shop_card_item.dart';
import 'package:ketnoitinhnguyenvienxemay/models/shop.dart';

void main() {
  group('ShopCardItem Widget Test - UC-03', () {
    const testShop = Shop(
      id: 'shop-test-1',
      ownerId: 'owner-test',
      name: 'Tiệm Sửa Xe Bách Khoa',
      category: 'repair_shop',
      phone: '0912345678',
      address: 'Số 1 Đại Cồ Việt, Hà Nội',
      latitude: 21.0070,
      longitude: 105.8430,
      openTime: '07:30:00',
      closeTime: '21:30:00',
      isOpen: true,
      rating: 4.9,
      reviewCount: 30,
      status: 'approved',
      distanceM: 450,
    );

    testWidgets('Hiển thị đầy đủ tên, địa chỉ, khoảng cách và badge mở cửa',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShopCardItem(shop: testShop),
          ),
        ),
      );

      expect(find.text('Tiệm Sửa Xe Bách Khoa'), findsOneWidget);
      expect(find.text('Số 1 Đại Cồ Việt, Hà Nội'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
      expect(find.text('Mở cửa'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Gọi ngay'), findsOneWidget);
      expect(find.text('Chỉ đường'), findsOneWidget);
    });
  });
}
