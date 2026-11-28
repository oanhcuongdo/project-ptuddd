import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'geocoding_helper.dart';

/// Kết quả định vị kèm thông tin trạng thái GPS và quyền truy cập (UC-02).
class LocationResult {
  const LocationResult({
    this.position,
    this.address,
    this.isGpsDisabled = false,
    this.isPermissionDenied = false,
    this.errorMessage,
  });

  final LatLng? position;
  final String? address;
  final bool isGpsDisabled;
  final bool isPermissionDenied;
  final String? errorMessage;

  bool get isSuccess => position != null && !isGpsDisabled && !isPermissionDenied;
}

/// Dịch vụ định vị GPS thiết bị và giải mã địa chỉ Reverse Geocoding (UC-02).
class LocationService {
  LocationService._();

  /// Vị trí mặc định tại trung tâm Hà Nội (Hồ Gươm) khi không có quyền GPS
  static const LatLng defaultHanoi = LatLng(21.028511, 105.854167);

  /// Lấy vị trí GPS hiện tại kèm kiểm tra quyền và dịch vụ định vị
  static Future<LocationResult> getCurrentLocation() async {
    // 1. Kiểm tra GPS của thiết bị đã bật chưa
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        isGpsDisabled: true,
        errorMessage: 'Vui lòng bật dịch vụ định vị GPS trên thiết bị.',
      );
    }

    // 2. Kiểm tra quyền truy cập vị trí của ứng dụng
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          position: defaultHanoi,
          isPermissionDenied: true,
          errorMessage: 'Ứng dụng đã bị từ chối quyền truy cập vị trí.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        position: defaultHanoi,
        isPermissionDenied: true,
        errorMessage: 'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.',
      );
    }

    // 3. Lấy tọa độ GPS thực tế
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      final address = await getAddressFromCoordinates(pos.latitude, pos.longitude);

      return LocationResult(
        position: latLng,
        address: address,
      );
    } catch (_) {
      // 4. Nếu GPS yếu hoặc timeout, thử lấy vị trí gần nhất đã lưu
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        final latLng = LatLng(lastPos.latitude, lastPos.longitude);
        final address = await getAddressFromCoordinates(lastPos.latitude, lastPos.longitude);
        return LocationResult(
          position: latLng,
          address: address,
          errorMessage: 'Tín hiệu GPS yếu, đang dùng vị trí gần nhất.',
        );
      }

      return const LocationResult(
        position: defaultHanoi,
        errorMessage: 'Không thể định vị GPS, dùng vị trí mặc định.',
      );
    }
  }

  /// Dịch tọa độ thành chuỗi tên đường/phường/quận (Reverse Geocoding)
  static Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    final address = await GeocodingHelper.reverseGeocode(latitude, longitude);
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return 'Tọa độ: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
