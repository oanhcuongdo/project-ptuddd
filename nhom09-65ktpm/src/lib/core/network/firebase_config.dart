import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Quản lý khởi tạo Firebase Authentication từ file `.env`
/// (chạy bằng `flutter run -d chrome --dart-define-from-file=.env`).
class FirebaseConfig {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  /// Khởi tạo Firebase an toàn cho cả Chrome Web và Android
  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    if (!isConfigured) {
      debugPrint(
        '[FirebaseConfig] Chưa có biến FIREBASE_* trong .env. '
        'Hãy điền key Firebase Console vào file .env để bật Đăng nhập thật.',
      );
      return;
    }

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? null : authDomain,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      ),
    );
    debugPrint('[FirebaseConfig] Kết nối Firebase thành công: $projectId');
  }
}
