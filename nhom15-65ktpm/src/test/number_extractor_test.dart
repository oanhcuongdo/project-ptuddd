import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/usecases/vietnamese_number_extractor.dart';

void main() {
  group('Vietnamese Number Extractor Tests (Module 4 - Cẩm Ly)', () {
    test('TC_NLP_01: Trích xuất số đơn lẻ và số dạng chữ số trong phạm vi 0-99', () {
      expect(VietnameseNumberExtractor.extractNumber('không'), 0);
      expect(VietnameseNumberExtractor.extractNumber('năm'), 5);
      expect(VietnameseNumberExtractor.extractNumber('số 7'), 7);
      expect(VietnameseNumberExtractor.extractNumber('15'), 15);
      expect(VietnameseNumberExtractor.extractNumber('bằng 8'), 8);
      expect(VietnameseNumberExtractor.extractNumber('dạ bằng 25'), 25);
      expect(VietnameseNumberExtractor.extractNumber('chín mươi chín'), 99);
    });

    test('TC_NLP_02: Trích xuất từ câu nói tự nhiên kèm từ đệm & dạ thưa của trẻ', () {
      expect(
        VietnameseNumberExtractor.extractNumber('dạ kết quả là bằng mười lăm'),
        15,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('thưa cô bằng hai mươi bốn'),
        24,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('dạ thưa cô kết quả bằng mười lăm ạ'),
        15,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('dạ con tính ra kết quả là mười ạ'),
        10,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('thưa thầy đáp án là chín ạ'),
        9,
      );
      expect(
        VietnameseNumberExtractor.extractNumber(
          'dạ kết quả là hai mươi lăm ạ',
        ),
        25,
      );
      expect(
        VietnameseNumberExtractor.extractNumber(
          'cô ơi đáp án là ba mươi mốt ạ',
        ),
        31,
      );
    });

    test('TC_NLP_03: Trích xuất các số hàng chục và biến thể vùng miền (lăm, nhăm, mốt, tư, hăm)', () {
      expect(VietnameseNumberExtractor.extractNumber('hai mươi lăm'), 25);
      expect(VietnameseNumberExtractor.extractNumber('hai nhăm'), 25);
      expect(VietnameseNumberExtractor.extractNumber('mười lăm'), 15);
      expect(VietnameseNumberExtractor.extractNumber('mười nhăm'), 15);
      expect(VietnameseNumberExtractor.extractNumber('hai mươi mốt'), 21);
      expect(VietnameseNumberExtractor.extractNumber('ba mươi mốt'), 31);
      expect(VietnameseNumberExtractor.extractNumber('ba mươi lăm'), 35);
      expect(VietnameseNumberExtractor.extractNumber('mười một'), 11);
      expect(VietnameseNumberExtractor.extractNumber('hai mươi'), 20);
      expect(VietnameseNumberExtractor.extractNumber('hăm mốt'), 21);
      expect(VietnameseNumberExtractor.extractNumber('hăm nhăm'), 25);
      expect(VietnameseNumberExtractor.extractNumber('bốn mươi tư'), 44);
      expect(VietnameseNumberExtractor.extractNumber('chín mươi chín'), 99);
    });

    test('TC_NLP_04: Xử lý câu từ chối ("con không biết", "chịu", "bỏ qua") -> bắt buộc trả về null', () {
      expect(VietnameseNumberExtractor.extractNumber('con không biết'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('dạ con không biết ạ'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('không biết đâu cô'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('chịu'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('con chịu'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('bỏ qua bài này'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('khó quá'), isNull);
    });

    test('TC_NLP_05: Xử lý số ngoài phạm vi 0–99 (hoặc số âm) -> bắt buộc trả về null', () {
      expect(VietnameseNumberExtractor.extractNumber('một trăm'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('một trăm linh năm'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('một trăm lẻ bảy'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('hai trăm hai mươi mốt'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('năm trăm'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('một nghìn'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('100'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('105'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('-5'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('âm năm'), isNull);
    });

    test('TC_NLP_06: Xử lý chuỗi rác / không có số hợp lệ -> trả về null', () {
      expect(VietnameseNumberExtractor.extractNumber('dạ con chào cô ạ'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('con thích ăn kem'), isNull);
      expect(VietnameseNumberExtractor.extractNumber(''), isNull);
      expect(VietnameseNumberExtractor.extractNumber('   '), isNull);
    });

    test('TC_NLP_07: Kiểm tra chi tiết cấu trúc ExtractionResult và nhận diện từ chối', () {
      final res1 = VietnameseNumberExtractor.extract('dạ thưa cô bằng hai mươi lăm ạ!');
      expect(res1.isNumber, isTrue);
      expect(res1.value, 25);

      final resRefusal1 = VietnameseNumberExtractor.extract('con không biết đâu cô ơi');
      expect(resRefusal1.isUnknown, isTrue);
      expect(resRefusal1.value, isNull);

      final resRefusal2 = VietnameseNumberExtractor.extract('bài này khó quá con chịu');
      expect(resRefusal2.isUnknown, isTrue);
      expect(resRefusal2.value, isNull);

      final resRefusal3 = VietnameseNumberExtractor.extract('bỏ qua bài này đi');
      expect(resRefusal3.isUnknown, isTrue);
      expect(resRefusal3.value, isNull);

      final resOutOfRange = VietnameseNumberExtractor.extract('một trăm linh năm');
      expect(resOutOfRange.isNumber, isFalse);
      expect(resOutOfRange.value, isNull);

      final resEmpty = VietnameseNumberExtractor.extract('   ');
      expect(resEmpty.isEmpty, isTrue);
      expect(resEmpty.value, isNull);
    });
  });
}
