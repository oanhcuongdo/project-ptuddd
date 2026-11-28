import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../repositories/auth_repository.dart';

/// Lấy vị trí GPS hiện tại, đổi lỗi quyền / GPS thành thông báo hiển thị được.
class LocationService {
  Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException(
        'GPS đang tắt. Vui lòng bật định vị và thử lại.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException(
        'Ứng dụng cần quyền truy cập vị trí để tiếp tục.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Quyền vị trí đã bị chặn. Vào Cài đặt của máy để cấp lại quyền.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw const AppException('Không xác định được vị trí, vui lòng thử lại.');
    }
  }
}
