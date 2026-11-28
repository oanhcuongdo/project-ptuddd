import 'package:flutter_test/flutter_test.dart';
import 'package:src/models/player_profile_model.dart';

void main() {
  group('Kiểm thử Đơn vị (Unit Test) - PlayerProfileModel', () {
    test('1. Khởi tạo đối tượng với giá trị mặc định chuẩn xác', () {
      const profile = PlayerProfileModel(
        id: 'test-uuid-12345',
        fullName: 'Nguyễn Minh Đức',
      );

      expect(profile.id, equals('test-uuid-12345'));
      expect(profile.fullName, equals('Nguyễn Minh Đức'));
      expect(profile.position, equals('Tiền đạo'));
      expect(profile.preferredFoot, equals('Chân phải'));
      expect(profile.jerseyNumber, equals(10));
      expect(profile.clubTeam, equals('FC 65KTPM'));
      expect(profile.avatarUrl, isNull);
    });

    test('2. Chuyển đổi JSON từ Supabase (fromJson) chính xác', () {
      final jsonMock = {
        'id': 'user-uuid-999',
        'full_name': 'Cristiano Ronaldo',
        'avatar_url': 'https://example.com/cr7.jpg',
        'position': 'Tiền đạo',
        'preferred_foot': 'Chân phải',
        'jersey_number': 7,
        'club_team': 'Al Nassr',
        'updated_at': '2026-11-22T08:00:00.000Z',
      };

      final profile = PlayerProfileModel.fromJson(jsonMock);

      expect(profile.id, equals('user-uuid-999'));
      expect(profile.fullName, equals('Cristiano Ronaldo'));
      expect(profile.avatarUrl, equals('https://example.com/cr7.jpg'));
      expect(profile.position, equals('Tiền đạo'));
      expect(profile.preferredFoot, equals('Chân phải'));
      expect(profile.jerseyNumber, equals(7));
      expect(profile.clubTeam, equals('Al Nassr'));
      expect(profile.updatedAt, isNotNull);
    });

    test('3. Chuyển đổi sang Map JSON (toJson) để gửi lên Supabase', () {
      const profile = PlayerProfileModel(
        id: 'user-uuid-10',
        fullName: 'Lionel Messi',
        avatarUrl: 'https://example.com/messi.jpg',
        position: 'Tiền đạo',
        preferredFoot: 'Chân trái',
        jerseyNumber: 10,
        clubTeam: 'Inter Miami',
      );

      final map = profile.toJson();

      expect(map['id'], equals('user-uuid-10'));
      expect(map['full_name'], equals('Lionel Messi'));
      expect(map['avatar_url'], equals('https://example.com/messi.jpg'));
      expect(map['position'], equals('Tiền đạo'));
      expect(map['preferred_foot'], equals('Chân trái'));
      expect(map['jersey_number'], equals(10));
      expect(map['club_team'], equals('Inter Miami'));
      expect(map.containsKey('updated_at'), isTrue);
    });

    test('4. copyWith cập nhật đúng thuộc tính chỉ định và giữ nguyên các thuộc tính khác', () {
      const initialProfile = PlayerProfileModel(
        id: 'user-uuid-1',
        fullName: 'Kylian Mbappe',
        position: 'Tiền đạo',
        jerseyNumber: 9,
        clubTeam: 'Real Madrid',
      );

      final updatedProfile = initialProfile.copyWith(
        jerseyNumber: 10,
        clubTeam: 'France National Team',
      );

      // Thuộc tính được cập nhật
      expect(updatedProfile.jerseyNumber, equals(10));
      expect(updatedProfile.clubTeam, equals('France National Team'));

      // Thuộc tính giữ nguyên
      expect(updatedProfile.id, equals('user-uuid-1'));
      expect(updatedProfile.fullName, equals('Kylian Mbappe'));
      expect(updatedProfile.position, equals('Tiền đạo'));
    });

    test('5. Xử lý an toàn khi JSON thiếu trường dữ liệu hoặc null', () {
      final incompleteJson = {
        'id': 'empty-user-001',
      };

      final profile = PlayerProfileModel.fromJson(incompleteJson);

      expect(profile.id, equals('empty-user-001'));
      expect(profile.fullName, equals('Cầu thủ mới'));
      expect(profile.position, equals('Tiền đạo'));
      expect(profile.preferredFoot, equals('Chân phải'));
      expect(profile.jerseyNumber, equals(10));
    });
  });
}
