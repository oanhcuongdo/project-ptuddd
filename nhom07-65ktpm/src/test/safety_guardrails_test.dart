import 'package:flutter_test/flutter_test.dart';
import 'package:dcsleep/data/services/safety_guardrails.dart';

void main() {
  group('SafetyGuardrails Tests', () {
    test('Blocks medication queries with Vietnamese accents', () {
      final res1 = SafetyGuardrails.evaluate('Tôi muốn mua thuốc ngủ');
      expect(res1.isBlocked, true);
      expect(res1.warningMessage, contains('tuyệt đối KHÔNG tư vấn'));

      final res2 = SafetyGuardrails.evaluate('Bác sĩ cho hỏi liều lượng thuốc seduxen');
      expect(res2.isBlocked, true);

      final res3 = SafetyGuardrails.evaluate('Uống thuốc an thần gì dễ ngủ?');
      expect(res3.isBlocked, true);
    });

    test('Blocks medication queries without accents (tieng Viet khong dau)', () {
      final res1 = SafetyGuardrails.evaluate('uong thuoc ngu lieu luong the nao');
      expect(res1.isBlocked, true);

      final res2 = SafetyGuardrails.evaluate('seduxen 5mg uong sao');
      expect(res2.isBlocked, true);

      final res3 = SafetyGuardrails.evaluate('uong stilnox hay diazepam de ngu');
      expect(res3.isBlocked, true);

      final res4 = SafetyGuardrails.evaluate('uong thuoc gi cho de ngu');
      expect(res4.isBlocked, true);
    });

    test('Detects red flag clinical symptoms', () {
      final res1 = SafetyGuardrails.evaluate('Tôi bị ngưng thở khi ngủ');
      expect(res1.isBlocked, true);
      expect(res1.warningMessage, contains('KHUYẾN CÁO KHẨN CẤP'));

      final res2 = SafetyGuardrails.evaluate('ngung tho khi ngu co nguy hiem khong');
      expect(res2.isBlocked, true);

      final res3 = SafetyGuardrails.evaluate('Dem ngu bi co giat va ao giac');
      expect(res3.isBlocked, true);
    });

    test('Allows safe sleep hygiene questions', () {
      final res1 = SafetyGuardrails.evaluate('Nên ngủ trưa bao nhiêu phút?');
      expect(res1.isBlocked, false);
      expect(res1.warningMessage, isNull);

      final res2 = SafetyGuardrails.evaluate('uong ca phe sau may gio thi mat ngu');
      expect(res2.isBlocked, false);

      final res3 = SafetyGuardrails.evaluate('Phòng ngủ nên để nhiệt độ bao nhiêu độ C?');
      expect(res3.isBlocked, false);
    });

    test('removeDiacritics cleans Vietnamese accents properly', () {
      expect(
        SafetyGuardrails.removeDiacritics('Ngủ ngon mỗi ngày cùng DCSleep'),
        'ngu ngon moi ngay cung dcsleep',
      );
    });
  });
}
