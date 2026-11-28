import 'package:firebase_core/firebase_core.dart';

/// Khởi tạo Firebase cho app.
///
/// Hai cách cấu hình, theo thứ tự ưu tiên:
///
/// 1. **`--dart-define`** — không cần commit file cấu hình nào:
///
///    ```bash
///    flutter run \
///      --dart-define=FIREBASE_API_KEY=... \
///      --dart-define=FIREBASE_APP_ID=... \
///      --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///      --dart-define=FIREBASE_PROJECT_ID=...
///    ```
///
/// 2. **File cấu hình của Firebase** (`android/app/google-services.json`,
///    `ios/Runner/GoogleService-Info.plist`) do `flutterfire configure` sinh ra.
///    File này không commit lên Git, mỗi thành viên tự thêm vào máy.
///
/// Không có giá trị bí mật nào được hardcode trong mã nguồn.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  /// Đọc cấu hình Firebase từ `--dart-define`; trả `null` nếu thiếu.
  static FirebaseOptions? optionsFromEnvironment() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        senderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
    );
  }

  /// Khởi tạo Firebase; ném `FirebaseException` nếu chưa cấu hình hoặc lỗi.
  static Future<void> initialize() async {
    final options = optionsFromEnvironment();
    if (options != null) {
      await Firebase.initializeApp(options: options);
      return;
    }
    // Không có --dart-define: Firebase đọc file cấu hình của nền tảng.
    await Firebase.initializeApp();
  }
}
