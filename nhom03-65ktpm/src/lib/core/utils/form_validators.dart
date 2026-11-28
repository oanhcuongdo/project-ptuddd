/// Kiểm tra dữ liệu form, trả về thông báo tiếng Việt hoặc `null` nếu hợp lệ.
class FormValidators {
  const FormValidators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Độ dài tối thiểu của mật khẩu (Firebase yêu cầu tối thiểu 6 ký tự).
  static const int minPasswordLength = 6;

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Vui lòng nhập email.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    if (password.length < minPasswordLength) {
      return 'Mật khẩu phải có ít nhất $minPasswordLength ký tự.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'Vui lòng nhập lại mật khẩu.';
    }
    if (value != password) {
      return 'Mật khẩu nhập lại không khớp.';
    }
    return null;
  }
}
