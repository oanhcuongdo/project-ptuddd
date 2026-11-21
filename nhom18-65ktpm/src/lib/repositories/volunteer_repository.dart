import '../models/volunteer_profile.dart';

/// Hợp đồng cho UC-13 và UC-11 (phần tình nguyện viên). Tùng triển khai.
abstract class VolunteerRepository {
  Future<VolunteerProfile?> myProfile();

  Future<VolunteerProfile> saveProfile({
    required String phone,
    required List<String> skills,
    String? tools,
    required String idCardUrl,
    required int serviceRadiusKm,
  });

  Future<void> setAvailable(bool value);

  /// Ghi `location` dạng EWKT: SRID=4326;POINT(lng lat).
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  });
}
