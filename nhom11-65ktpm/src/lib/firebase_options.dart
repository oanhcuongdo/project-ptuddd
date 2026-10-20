// File generated for Study Material Manager Firebase Integration
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // Cấu hình Firebase Web (Sử dụng project study-material-nhom11 của nhóm)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBJhoy60qOfsNU9b0zzXZfhyMZnA9jbmOQ',
    appId: '1:693074823537:web:42784b0b0830f917d48ed0',
    messagingSenderId: '693074823537',
    projectId: 'study-material-nhom11',
    authDomain: 'study-material-nhom11.firebaseapp.com',
    storageBucket: 'study-material-nhom11.firebasestorage.app',
  );

  // Cấu hình Firebase Android (Từ google-services.json chính thức của nhóm)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJhoy60qOfsNU9b0zzXZfhyMZnA9jbmOQ',
    appId: '1:693074823537:android:42784b0b0830f917d48ed0',
    messagingSenderId: '693074823537',
    projectId: 'study-material-nhom11',
    storageBucket: 'study-material-nhom11.firebasestorage.app',
  );

  // Cấu hình Firebase iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJhoy60qOfsNU9b0zzXZfhyMZnA9jbmOQ',
    appId: '1:693074823537:ios:42784b0b0830f917d48ed0',
    messagingSenderId: '693074823537',
    projectId: 'study-material-nhom11',
    storageBucket: 'study-material-nhom11.firebasestorage.app',
    androidClientId: '693074823537-rkmoa4pun2ghhpae5v0rplsa6fi2pb5h.apps.googleusercontent.com',
    iosBundleId: 'vn.nhom11.studydocs.study_material_manager',
  );
}
