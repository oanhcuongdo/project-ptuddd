import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/features/call/call_helper.dart';

void main() {
  group('CallHelper - UC-05', () {
    test('cleanPhone loại bỏ khoảng trắng, dấu gạch và dấu chấm', () {
      expect(CallHelper.cleanPhone(' 0912 345 678 '), '0912345678');
      expect(CallHelper.cleanPhone('0912-345-678'), '0912345678');
      expect(CallHelper.cleanPhone('(024) 3858.1234'), '02438581234');
      expect(CallHelper.cleanPhone('+84 912 345 678'), '+84912345678');
      expect(CallHelper.cleanPhone(null), '');
      expect(CallHelper.cleanPhone('   '), '');
    });
  });
}
