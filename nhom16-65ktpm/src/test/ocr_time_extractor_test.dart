import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/features/proof_submission/services/ocr_time_extractor.dart';

void main() {
  group('OcrTimeExtractor Unit Tests (Sprint 3 - Stage 2)', () {
    const extractor = OcrTimeExtractor();

    test('Nhận diện chuẩn giờ đồng hồ định dạng HH:mm AM và ngày dd/MM/yyyy', () {
      const text = '05:42 AM - 23/11/2026\nÔn tập Lập trình Flutter';
      final info = extractor.extract(text);

      expect(info.hasTime, isTrue);
      expect(info.formattedTime24h, '05:42');
      expect(info.hour, 5);
      expect(info.minute, 42);
      expect(info.extractedDate, '23/11/2026');
      expect(info.periodLabel, 'Sáng sớm');
      expect(info.isEarlyWakeUpValid, isTrue);
    });

    test('Nhận diện định dạng giờ viết tắt 5h18 trên đồng hồ điện tử', () {
      const text = 'ALMW 5h18 - 23-11-2026\nĐọc tài liệu Clean Architecture';
      final info = extractor.extract(text);

      expect(info.formattedTime24h, '05:18');
      expect(info.extractedDate, '23/11/2026');
      expect(info.isEarlyWakeUpValid, isTrue);
    });

    test('Chuyển đổi đúng giờ 12h (PM) sang định dạng 24h', () {
      const text = '07:15 PM - Lớp học tình thương Toán lớp 5';
      final info = extractor.extract(text);

      expect(info.formattedTime24h, '19:15');
      expect(info.hour, 19);
      expect(info.periodLabel, 'Buổi tối');
      expect(info.isEarlyWakeUpValid, isFalse);
    });

    test('Đánh dấu không hợp lệ dậy sớm khi giờ chụp trễ sau 06:00', () {
      const text = '07:25 - Check-in bàn học buổi sáng';
      final info = extractor.extract(text);

      expect(info.formattedTime24h, '07:25');
      expect(info.periodLabel, 'Buổi sáng');
      expect(info.isEarlyWakeUpValid, isFalse);
    });

    test('Xử lý an toàn khi văn bản không chứa mốc giờ hoặc rỗng', () {
      final noTime = extractor.extract('Hoàn thành 5 bài tập thuật toán');
      expect(noTime.hasTime, isFalse);
      expect(noTime.formattedTime24h, isNull);
      expect(noTime.isEarlyWakeUpValid, isFalse);

      final empty = extractor.extract('   ');
      expect(empty.hasTime, isFalse);
    });
  });
}
