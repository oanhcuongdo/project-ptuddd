import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/features/proof_submission/services/ocr_homework_matcher.dart';

void main() {
  group('OcrHomeworkMatcher Unit Tests (Sprint 3 - Stage 3)', () {
    const matcher = OcrHomeworkMatcher();

    test('Nhận diện đúng chữ trên bài làm Giải toán & Lập trình (ch_03)', () {
      const sample =
          '21:15 - LeetCode & Toán rời rạc\nHoàn thành 5 bài tập thuật toán Quy hoạch động & Cấu trúc dữ liệu\nPassed: 5/5 test cases';
      final result = matcher.matchHomeworkContent(
        sample,
        targetChallengeId: 'ch_03',
      );

      expect(result.suggestedChallengeId, 'ch_03');
      expect(result.suggestedCategory, 'Học tập');
      expect(result.isTargetChallengeMatched, isTrue);
      expect(result.matchedKeywords, containsAll(['toán', 'thuật toán', 'leetcode']));
      expect(result.homeworkMetrics['so_bai_hoan_thanh'], '5 bài');
      expect(result.contentScore, greaterThanOrEqualTo(45));
    });

    test('Nhận diện đúng chữ trên bảng lớp học Gia sư tình thương (ch_02)', () {
      const sample =
          '19:00 - Lớp học tình thương\nBài giảng: Toán tư duy & Phân số lớp 5\nSĩ số: 12 học sinh';
      final result = matcher.matchHomeworkContent(
        sample,
        targetChallengeId: 'ch_02',
      );

      expect(result.suggestedChallengeId, 'ch_02');
      expect(result.suggestedCategory, 'Gia sư');
      expect(result.isTargetChallengeMatched, isTrue);
      expect(result.homeworkMetrics['si_so_lop'], '12 học sinh');
    });

    test('Nhận diện đúng cự ly chạy bộ km trên màn hình Strava (ch_04)', () {
      const sample =
          '06:15 - Strava Running Activity\nDistance: 3.45 km | Pace: 5:40 /km';
      final result = matcher.matchHomeworkContent(
        sample,
        targetChallengeId: 'ch_04',
      );

      expect(result.suggestedChallengeId, 'ch_04');
      expect(result.suggestedCategory, 'Sức khỏe');
      expect(result.isTargetChallengeMatched, isTrue);
      expect(result.homeworkMetrics['quang_duong'], '3.45 km');
    });

    test('Giảm điểm khi nội dung bài làm không khớp với thử thách đã chọn', () {
      const sample = 'Strava Running Activity Distance: 3.0 km';
      final mismatched = matcher.matchHomeworkContent(
        sample,
        targetChallengeId: 'ch_02', // Đang chọn Gia sư nhưng nộp ảnh chạy bộ
      );

      expect(mismatched.suggestedChallengeId, 'ch_04');
      expect(mismatched.isTargetChallengeMatched, isFalse);
      expect(mismatched.contentScore, lessThanOrEqualTo(20));
    });
  });
}
