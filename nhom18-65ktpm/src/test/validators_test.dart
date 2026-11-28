import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/core/validators.dart';

void main() {
  test('validateEmail chặn email sai', () {
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('abc'), isNotNull);
    expect(validateEmail('a@b'), isNotNull);
    expect(validateEmail('a@b.com'), isNull);
  });

  test('validatePassword yêu cầu tối thiểu 6 ký tự', () {
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
  });

  test('validatePhone chấp nhận đầu 0 và +84', () {
    expect(validatePhone('0912345678'), isNull);
    expect(validatePhone('+84912345678'), isNull);
    expect(validatePhone('12345'), isNotNull);
    expect(validatePhone(''), isNotNull);
  });

  test('validateRequired bỏ qua khoảng trắng', () {
    expect(validateRequired('   ', 'họ tên'), isNotNull);
    expect(validateRequired('Thuận', 'họ tên'), isNull);
  });
}
