import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/data/models/proof_model.dart';

void main() {
  group('ProofModel Unit Tests', () {
    final sampleDate = DateTime(2026, 11, 20, 5, 45);

    final testProof = ProofModel(
      id: 'proof_test_01',
      challengeId: 'ch_01',
      challengeTitle: 'Dậy sớm trước 6:00 sáng',
      memberName: 'Lê Anh Tuấn',
      imagePath: '/data/user/0/com.example.gooddeeds/app_flutter/proof_01.jpg',
      ocrExtractedText: 'Báo thức: 05:45 AM - Học bài chăm chỉ',
      detectedTime: '05:45',
      submittedAt: sampleDate,
      status: ProofStatus.pending,
      rewardAmount: 20000.0,
      note: 'Hôm nay dậy sớm giải bài tập Flutter',
      adminFeedback: null,
    );

    test('Kiểm tra khởi tạo và các thuộc tính cơ bản', () {
      expect(testProof.id, 'proof_test_01');
      expect(testProof.challengeId, 'ch_01');
      expect(testProof.challengeTitle, 'Dậy sớm trước 6:00 sáng');
      expect(testProof.memberName, 'Lê Anh Tuấn');
      expect(testProof.detectedTime, '05:45');
      expect(testProof.rewardAmount, 20000.0);
      expect(testProof.note, 'Hôm nay dậy sớm giải bài tập Flutter');
      expect(testProof.adminFeedback, isNull);
    });

    test('Kiểm tra các getters trạng thái duyệt: isPending, isApproved, isRejected', () {
      // 1. Trạng thái Pending
      expect(testProof.isPending, isTrue);
      expect(testProof.isApproved, isFalse);
      expect(testProof.isRejected, isFalse);
      expect(testProof.statusDisplay, 'Chờ duyệt');

      // 2. Trạng thái Approved
      final approvedProof = testProof.copyWith(
        status: ProofStatus.approved,
        adminFeedback: 'Ảnh chụp rõ nét. Đã duyệt!',
      );
      expect(approvedProof.isPending, isFalse);
      expect(approvedProof.isApproved, isTrue);
      expect(approvedProof.isRejected, isFalse);
      expect(approvedProof.statusDisplay, 'Đã duyệt');
      expect(approvedProof.adminFeedback, 'Ảnh chụp rõ nét. Đã duyệt!');

      // 3. Trạng thái Rejected
      final rejectedProof = testProof.copyWith(
        status: ProofStatus.rejected,
        adminFeedback: 'Ảnh mờ không rõ thời gian.',
      );
      expect(rejectedProof.isPending, isFalse);
      expect(rejectedProof.isApproved, isFalse);
      expect(rejectedProof.isRejected, isTrue);
      expect(rejectedProof.statusDisplay, 'Từ chối');
    });

    test('Kiểm tra định dạng hiển thị tiền thưởng và ngày nộp', () {
      expect(testProof.formattedRewardAmount, contains('20.000'));
      expect(testProof.formattedRewardAmount, contains('đ'));
      expect(testProof.formattedSubmittedAt, '05:45 - 20/11/2026');
    });

    test('Kiểm tra ánh xạ SQLite: toMap() và fromMap()', () {
      final map = testProof.toMap();

      expect(map['id'], 'proof_test_01');
      expect(map['challengeId'], 'ch_01');
      expect(map['status'], 'pending');
      expect(map['rewardAmount'], 20000.0);
      expect(map['submittedAt'], sampleDate.toIso8601String());

      final fromMapModel = ProofModel.fromMap(map);
      expect(fromMapModel, equals(testProof));
    });

    test('Kiểm tra JSON serialization: toJson() và fromJson()', () {
      final json = testProof.toJson();
      expect(json['id'], 'proof_test_01');
      expect(json['status'], 'pending');

      final fromJsonModel = ProofModel.fromJson(json);
      expect(fromJsonModel, equals(testProof));

      final jsonString = testProof.toJsonString();
      final fromStringModel = ProofModel.fromJsonString(jsonString);
      expect(fromStringModel, equals(testProof));
    });

    test('Kiểm tra copyWith()', () {
      final updated = testProof.copyWith(
        memberName: 'Nguyễn Văn Huỳnh',
        rewardAmount: 30000.0,
      );

      expect(updated.id, testProof.id);
      expect(updated.memberName, 'Nguyễn Văn Huỳnh');
      expect(updated.rewardAmount, 30000.0);
      expect(updated.challengeId, testProof.challengeId);
      expect(updated.imagePath, testProof.imagePath);
    });

    test('Kiểm tra toán tử bằng nhau == và hashCode', () {
      final duplicate = ProofModel.fromMap(testProof.toMap());
      expect(duplicate, equals(testProof));
      expect(duplicate.hashCode, equals(testProof.hashCode));
    });
  });
}

