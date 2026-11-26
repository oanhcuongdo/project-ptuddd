/// Cấu hình lúc build, truyền bằng `--dart-define`.
abstract final class AppConfig {
  /// `--dart-define=FAKE_DATA=true`: mọi hợp đồng dùng bản giả, kể cả khi bản
  /// thật đã xong. Hữu ích khi không có server / mạng, hoặc để demo ổn định.
  static const bool fakeData = bool.fromEnvironment('FAKE_DATA');
}
