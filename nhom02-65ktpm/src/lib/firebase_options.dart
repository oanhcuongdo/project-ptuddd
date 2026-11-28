// FILE TẠM — sẽ bị GHI ĐÈ khi chạy `flutterfire configure`.
//
// Các bước (xem README):
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<firebase-project-id> --platforms=android,ios
//
// Trước khi cấu hình, ứng dụng sẽ hiện màn hình hướng dẫn thay vì crash.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Chưa cấu hình Firebase. Hãy chạy "flutterfire configure" trong thư mục src/.',
    );
  }
}
