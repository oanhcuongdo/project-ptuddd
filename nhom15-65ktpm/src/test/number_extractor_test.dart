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
    });

    test('TC_NLP_04: Trả về null khi câu nói không chứa số hợp lệ', () {
      expect(VietnameseNumberExtractor.extractNumber('con không biết'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('dạ con chào cô ạ'), isNull);
      expect(VietnameseNumberExtractor.extractNumber(''), isNull);
    });
  });
}
