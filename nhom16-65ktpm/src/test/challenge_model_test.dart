import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/data/models/challenge_model.dart';

void main() {
  group('ChallengeModel Unit Tests', () {
    const testChallenge = ChallengeModel(
      id: 'ch_test_01',
      title: 'Dậy sớm trước 6:00 sáng',
      description: 'Chụp ảnh bàn học hoặc đồng hồ trước 6h sáng',
      rewardAmount: 20000.0,
      category: 'Kỷ luật',
      icon: 'wb_sunny',
      isActive: true,
    );

    test('Kiểm tra khởi tạo và các thuộc tính cơ bản', () {
      expect(testChallenge.id, 'ch_test_01');
      expect(testChallenge.title, 'Dậy sớm trước 6:00 sáng');
      expect(testChallenge.rewardAmount, 20000.0);
      expect(testChallenge.category, 'Kỷ luật');
      expect(testChallenge.icon, 'wb_sunny');
      expect(testChallenge.isActive, isTrue);
    });

    test('Kiểm tra hàm validation isValid()', () {
      expect(testChallenge.isValid(), isTrue);

      const invalidChallengeEmptyId = ChallengeModel(
        id: '',
        title: 'Tiêu đề hợp lệ',
        description: 'Mô tả',
        rewardAmount: 10000.0,
        category: 'Học tập',
        icon: 'book',
      );
      expect(invalidChallengeEmptyId.isValid(), isFalse);

      const invalidChallengeNegativeReward = ChallengeModel(
        id: 'ch_02',
        title: 'Tiêu đề',
        description: 'Mô tả',
        rewardAmount: -5000.0,
        category: 'Học tập',
        icon: 'book',
      );
      expect(invalidChallengeNegativeReward.isValid(), isFalse);
    });

    test('Kiểm tra định dạng tiền thưởng formattedRewardAmount', () {
      expect(testChallenge.formattedRewardAmount, contains('20.000'));
      expect(testChallenge.formattedRewardAmount, contains('đ'));
    });

    test('Kiểm tra SQLite mapping toMap() và fromMap()', () {
      final map = testChallenge.toMap();
      expect(map['id'], 'ch_test_01');
      expect(map['title'], 'Dậy sớm trước 6:00 sáng');
      expect(map['rewardAmount'], 20000.0);
      expect(map['isActive'], 1);

      final fromMapModel = ChallengeModel.fromMap(map);
      expect(fromMapModel, equals(testChallenge));
    });

    test('Kiểm tra JSON serialization toJson() và fromJson()', () {
      final json = testChallenge.toJson();
      expect(json['id'], 'ch_test_01');
      expect(json['isActive'], isTrue);

      final fromJsonModel = ChallengeModel.fromJson(json);
      expect(fromJsonModel, equals(testChallenge));

      final jsonString = testChallenge.toJsonString();
      final fromStringModel = ChallengeModel.fromJsonString(jsonString);
      expect(fromStringModel, equals(testChallenge));
    });

    test('Kiểm tra copyWith()', () {
      final updated = testChallenge.copyWith(
        rewardAmount: 30000.0,
        isActive: false,
      );

      expect(updated.id, testChallenge.id);
      expect(updated.rewardAmount, 30000.0);
      expect(updated.isActive, isFalse);
      expect(updated.category, testChallenge.category);
    });
  });
}
