import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Khởi tạo Firebase theo đúng thứ tự:
/// 1. Firebase.initializeApp
/// 2. App Check (BẮT BUỘC trước khi dùng Firebase AI Logic)
/// 3. Firestore offline persistence
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // App Check chứng minh request đến từ app thật, chống lạm dụng quota Gemini.
    // - Bản debug: Debug provider. Token debug in ra logcat, cần thêm vào
    //   Firebase Console > App Check > Apps > Manage debug tokens.
    // - Bản release: Play Integrity (Android) / App Attest (iOS).
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestProvider()
          : const AppleDebugProvider(),
    );

    // Bật cache offline: xem nhật ký và thêm món khi mất mạng,
    // có mạng lại thì Firestore tự đồng bộ.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
