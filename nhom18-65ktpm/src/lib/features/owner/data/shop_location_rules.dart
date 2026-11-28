class ShopLocationRules {
  static bool inVietnamBounds(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= 8.0 &&
        latitude <= 23.5 &&
        longitude >= 102.0 &&
        longitude <= 110.0;
  }

  static String? validateCoordinates(double? latitude, double? longitude) {
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return 'Tọa độ không hợp lệ.';
    }
    if (!inVietnamBounds(latitude, longitude)) {
      return 'Vị trí không nằm trong phạm vi phục vụ.';
    }
    return null;
  }
}
