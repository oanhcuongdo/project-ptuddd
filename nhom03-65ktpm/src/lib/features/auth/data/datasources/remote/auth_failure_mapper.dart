import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../core/error/failure.dart';

/// Chuyển lỗi của Firebase Auth thành [AuthFailure] tiếng Việt.
///
/// Tách riêng khỏi datasource để test được mà không cần khởi tạo Firebase.
/// Mã lỗi tham khảo: https://firebase.google.com/docs/auth/admin/errors
AuthFailure mapFirebaseAuthException(FirebaseAuthException exception) {
  final code = exception.code;
  return AuthFailure(_messageFor(code), code: code);
}

/// Lỗi phát sinh khi tạo/đăng nhập tài khoản mà Firebase không gắn mã lỗi
/// (ví dụ: response rỗng, lỗi nền tảng).
AuthFailure mapFirebaseAuthFailure(Object error) {
  if (error is FirebaseAuthException) {
    return mapFirebaseAuthException(error);
  }
  return const AuthFailure('Không thể xác thực. Vui lòng thử lại.');
}

String _messageFor(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Email không hợp lệ.';
    case 'user-disabled':
      return 'Tài khoản này đã bị khoá. Vui lòng liên hệ quản trị viên.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email hoặc mật khẩu không đúng.';
    case 'email-already-in-use':
      return 'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.';
    case 'weak-password':
      return 'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.';
    case 'missing-password':
      return 'Vui lòng nhập mật khẩu.';
    case 'network-request-failed':
      return 'Không có kết nối mạng. Kiểm tra Wi-Fi/4G rồi thử lại.';
    case 'too-many-requests':
      return 'Bạn đã thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.';
    case 'operation-not-allowed':
      return 'Đăng nhập bằng email/mật khẩu chưa được bật cho ứng dụng.';
    case 'requires-recent-login':
      return 'Phiên đăng nhập đã cũ. Vui lòng đăng nhập lại.';
    case 'internal-error':
      return 'Máy chủ xác thực gặp sự cố. Vui lòng thử lại sau.';
    default:
      return 'Không thể xác thực. Vui lòng thử lại.';
  }
}
