/// Cấu hình lúc build, truyền bằng `--dart-define`.
abstract final class AppConfig {
  /// `--dart-define=FAKE_DATA=true`: mọi hợp đồng dùng bản giả, kể cả khi bản
  /// thật đã xong. Hữu ích khi không có server / mạng, hoặc để demo ổn định.
  static const bool fakeData = bool.fromEnvironment('FAKE_DATA');

  /// `--dart-define=DEV_TRUST_SELF_SIGNED=true`: bản debug chấp nhận chứng chỉ
  /// tự ký của host trong `API_BASE_URL`, để gọi stack Docker (Nginx HTTPS) ở máy dev.
  /// Bản release luôn bỏ qua cờ này.
  static const bool devTrustSelfSigned = bool.fromEnvironment('DEV_TRUST_SELF_SIGNED');
}
