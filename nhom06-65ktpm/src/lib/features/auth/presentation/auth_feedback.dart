import '../domain/auth_repository.dart';

String authErrorMessage(Object? error) => switch (error) {
  AuthFailure.invalidCredentials => 'Email hoặc mật khẩu không đúng.',
  AuthFailure.invalidEmail => 'Vui lòng nhập địa chỉ email hợp lệ.',
  AuthFailure.weakPassword => 'Mật khẩu chưa đạt yêu cầu của hệ thống.',
  AuthFailure.emailAlreadyInUse => 'Email này đã được sử dụng. Hãy đăng nhập.',
  AuthFailure.accountDisabled => 'Tài khoản đã bị vô hiệu hóa.',
  AuthFailure.network => 'Mất kết nối mạng. Hãy kiểm tra và thử lại.',
  AuthFailure.rateLimited => 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
  AuthFailure.googleCanceled => 'Chưa hoàn tất đăng nhập Google.',
  AuthFailure.providerUnavailable =>
    'Phương thức đăng nhập chưa sẵn sàng. Hãy thử lại hoặc dùng cách khác.',
  AuthFailure.emailSignInRequired =>
    'Tài khoản đã dùng phương thức đăng nhập khác. Hãy đăng nhập bằng cách đó.',
  AuthFailure.sessionExpired => 'Phiên đã hết hạn. Hãy đăng nhập lại.',
  AuthFailure.awaitingDataAccess =>
    'Tài khoản đang chờ quyền truy cập dữ liệu.',
  _ => 'Không thể hoàn tất thao tác. Vui lòng thử lại.',
};
