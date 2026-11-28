import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/map/location_service.dart';

void main() {
  group('LocationService - UC-02', () {
    test('defaultHanoi có tọa độ chính xác tại Hà Nội', () {
      expect(LocationService.defaultHanoi.latitude, closeTo(21.0285, 0.001));
      expect(LocationService.defaultHanoi.longitude, closeTo(105.8542, 0.001));
    });

    test('LocationResult xác định isSuccess chính xác', () {
      const resSuccess = LocationResult(
        position: LocationService.defaultHanoi,
        address: 'Hà Nội',
      );
      expect(resSuccess.isSuccess, isTrue);

      const resGpsOff = LocationResult(
        isGpsDisabled: true,
      );
      expect(resGpsOff.isSuccess, isFalse);

      const resPermDenied = LocationResult(
        isPermissionDenied: true,
      );
      expect(resPermDenied.isSuccess, isFalse);
    });
  });
}
