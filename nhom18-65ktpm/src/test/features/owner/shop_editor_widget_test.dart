import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/map/geocoding_helper.dart';
import 'package:ketnoitinhnguyenvienxemay/features/owner/screens/shop_editor_screen.dart';
import 'package:ketnoitinhnguyenvienxemay/features/owner/screens/shop_location_picker.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('UC-09: Màn hình đăng ký hiển thị trường bắt buộc', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopEditorScreen()));
    expect(find.text('Đăng ký tiệm'), findsOneWidget);
    expect(find.text('Tên tiệm *'), findsOneWidget);
    expect(find.text('Loại cơ sở *'), findsOneWidget);
  });

  testWidgets(
    'UC-10: ShopLocationPicker mở an toàn không lỗi null trên nền tảng không có native geocoding',
    (tester) async {
      ShopPickedLocation? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  picked = await Navigator.of(context).push<ShopPickedLocation>(
                    MaterialPageRoute(
                      builder: (_) => const ShopLocationPicker(
                        initialPosition: LatLng(21.0285, 105.8542),
                        initialAddress: 'Hoàn Kiếm, Hà Nội',
                        autoLocate: false,
                      ),
                    ),
                  );
                },
                child: const Text('Mở bản đồ'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở bản đồ'));
      await tester.pumpAndSettle();

      expect(find.text('Ghim vị trí tiệm'), findsOneWidget);
      expect(find.text('21.028500'), findsOneWidget);
      expect(find.text('105.854200'), findsOneWidget);
      expect(find.text('Hoàn Kiếm, Hà Nội'), findsOneWidget);

      await tester.ensureVisible(find.text('Xác nhận vị trí này'));
      await tester.tap(find.text('Xác nhận vị trí này'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.address, 'Hoàn Kiếm, Hà Nội');
      expect(picked!.position.latitude, closeTo(21.0285, 0.0001));
    },
  );

  testWidgets(
    'UC-10: ShopLocationPicker mở mới hoàn toàn (không có initialPosition) không văng lỗi null',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ShopLocationPicker(autoLocate: false)),
      );
      await tester.pump();
      expect(find.text('Ghim vị trí tiệm'), findsOneWidget);
      expect(find.text('Chạm vào bản đồ để đặt ghim vị trí'), findsOneWidget);
    },
  );

  test('GeocodingHelper parse phản hồi Nominatim hợp lệ', () {
    final addr = GeocodingHelper.parseNominatimReverse({
      'address': {
        'house_number': '1',
        'road': 'Đại Cồ Việt',
        'suburb': 'Bách Khoa',
        'city_district': 'Hai Bà Trưng',
        'city': 'Hà Nội',
      },
    });
    expect(addr, '1 Đại Cồ Việt, Bách Khoa, Hai Bà Trưng, Hà Nội');

    final pos = GeocodingHelper.parseNominatimSearch([
      {'lat': '21.0070', 'lon': '105.8430'},
    ]);
    expect(pos, isNotNull);
    expect(pos!.latitude, closeTo(21.0070, 0.0001));
    expect(pos.longitude, closeTo(105.8430, 0.0001));
  });
}
