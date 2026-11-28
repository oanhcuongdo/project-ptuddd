import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/auth/data/datasources/remote/auth_failure_mapper.dart';

void main() {
  AuthFailure mapCode(String code) {
    return mapFirebaseAuthException(FirebaseAuthException(code: code));
  }

  test('sai email hoặc mật khẩu', () {
    expect(
      mapCode('wrong-password').message,
      'Email hoặc mật khẩu không đúng.',
    );
    expect(
      mapCode('user-not-found').message,
      'Email hoặc mật khẩu không đúng.',
    );
    expect(
      mapCode('invalid-credential').message,
      'Email hoặc mật khẩu không đúng.',
    );
  });

  test('email đã được đăng ký', () {
    expect(
      mapCode('email-already-in-use').message,
      'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.',
    );
  });

  test('mật khẩu quá yếu', () {
    expect(
      mapCode('weak-password').message,
      'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.',
    );
  });

  test('mất mạng được nhận diện là lỗi mạng', () {
    final failure = mapCode('network-request-failed');

    expect(failure.isNetworkError, isTrue);
    expect(failure.message, contains('kết nối mạng'));
    expect(mapCode('wrong-password').isNetworkError, isFalse);
  });

  test('mã lỗi lạ vẫn trả thông báo tiếng Việt kèm mã gốc', () {
    final failure = mapCode('some-new-code');

    expect(failure.message, 'Không thể xác thực. Vui lòng thử lại.');
    expect(failure.code, 'some-new-code');
  });

  test(
    'lỗi không phải FirebaseAuthException cũng được bọc thành AuthFailure',
    () {
      final failure = mapFirebaseAuthFailure(StateError('boom'));

      expect(failure, isA<AuthFailure>());
      expect(failure.code, isNull);
    },
  );
}
