/// Validate dùng chung cho form đăng nhập/đăng ký.
/// Tách khỏi widget để test được mà không cần Supabase.
String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) return 'Vui lòng nhập $label';
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Vui lòng nhập email';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return ok ? null : 'Email không hợp lệ';
}

String? validatePassword(String? value) {
  if (value == null || value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
  return null;
}

String? validatePhone(String? value) {
  final phone = value?.replaceAll(' ', '') ?? '';
  if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
  final ok = RegExp(r'^(0|\+84)\d{9}$').hasMatch(phone);
  return ok ? null : 'Số điện thoại không hợp lệ (VD: 0912345678)';
}
