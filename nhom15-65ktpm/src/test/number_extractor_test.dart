import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/usecases/vietnamese_number_extractor.dart';

void main() {
  group('Vietnamese Number Extractor Tests (Module 4 - Cẩm Ly)', () {
    test('TC_NLP_01: Trích xuất số đơn lẻ và số dạng chữ số', () {
      expect(VietnameseNumberExtractor.extractNumber('năm'), 5);
      expect(VietnameseNumberExtractor.extractNumber('số 7'), 7);
      expect(VietnameseNumberExtractor.extractNumber('15'), 15);
      expect(VietnameseNumberExtractor.extractNumber('bằng 8'), 8);
    });

    test('TC_NLP_02: Trích xuất từ câu nói tự nhiên kèm từ dạ thưa của trẻ', () {
      expect(
        VietnameseNumberExtractor.extractNumber(
          'dạ thưa cô kết quả bằng mười lăm ạ',
        ),
        15,
      );
      expect(
        VietnameseNumberExtractor.extractNumber(
          'dạ con tính ra kết quả là mười ạ',
        ),
        10,
      );
      expect(
        VietnameseNumberExtractor.extractNumber(
          'thưa thầy đáp án là chín ạ',
        ),
        9,
      );
    });

    test('TC_NLP_03: Trích xuất các số hàng chục và phương ngữ', () {
      expect(VietnameseNumberExtractor.extractNumber('hai mươi mốt'), 21);
      expect(VietnameseNumberExtractor.extractNumber('ba mươi lăm'), 35);
      expect(VietnameseNumberExtractor.extractNumber('mười một'), 11);
      expect(VietnameseNumberExtractor.extractNumber('hai mươi'), 20);
      expect(VietnameseNumberExtractor.extractNumber('hăm mốt'), 21);
      expect(VietnameseNumberExtractor.extractNumber('hăm nhăm'), 25);
      expect(VietnameseNumberExtractor.extractNumber('bốn mươi tư'), 44);
    });

    test('TC_NLP_04: Trả về null khi câu nói không chứa số hợp lệ', () {
      expect(VietnameseNumberExtractor.extractNumber('con không biết'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('dạ con chào cô ạ'), isNull);
      expect(VietnameseNumberExtractor.extractNumber(''), isNull);
    });

    test('TC_NLP_05: Trích xuất số hàng trăm và các cách đọc linh/lẻ', () {
      expect(VietnameseNumberExtractor.extractNumber('một trăm linh năm'), 105);
      expect(VietnameseNumberExtractor.extractNumber('một trăm lẻ bảy'), 107);
      expect(VietnameseNumberExtractor.extractNumber('hai trăm hai mươi mốt'), 221);
      expect(VietnameseNumberExtractor.extractNumber('năm trăm'), 500);
    });

    test('TC_NLP_06: Kiểm tra chi tiết cấu trúc ExtractionResult và nhận diện từ chối', () {
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

      final resEmpty = VietnameseNumberExtractor.extract('   ');
      expect(resEmpty.isEmpty, isTrue);
    });
  });
}
