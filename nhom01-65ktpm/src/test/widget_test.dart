import 'package:flutter_test/flutter_test.dart';
import 'package:src/models/player_profile_model.dart';

void main() {
  test('Smoke test kiểm tra khởi tạo và định dạng dữ liệu cầu thủ', () {
    const profile = PlayerProfileModel(
      id: 'smoke-test-uuid',
      fullName: 'Nguyễn Minh Đức',
      jerseyNumber: 10,
      position: 'Tiền đạo',
    );
    expect(profile.fullName, equals('Nguyễn Minh Đức'));
    expect(profile.jerseyNumber, equals(10));
    expect(profile.position, equals('Tiền đạo'));
  });
}
