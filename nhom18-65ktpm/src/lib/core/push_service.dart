import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'env.dart';
import 'supabase_client.dart';

/// FCM cho chủ tiệm / TNV nhận cảnh báo SOS khi app ở nền hoặc đã tắt.
/// Payload do Edge Function `notify-sos` gửi: {sos_id, issue_type, lat, lng}.
/// Chưa điền FIREBASE_* trong env.json thì bỏ qua: app vẫn nhận ca qua realtime khi đang mở.
abstract final class PushService {
  static bool _ready = false;
  static String? _initialSosId;
  static StreamSubscription<String>? _tokenSubscription;
  static final _sosAlerts = StreamController<String>.broadcast();

  static Future<void> initialize() async {
    if (!Env.isFirebaseConfigured) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: Env.firebaseApiKey,
          appId: Env.firebaseAppId,
          messagingSenderId: Env.firebaseMessagingSenderId,
          projectId: Env.firebaseProjectId,
        ),
      );
      FirebaseMessaging.onMessage.listen(_emit);
      FirebaseMessaging.onMessageOpenedApp.listen(_emit);
      _initialSosId = _sosId(
        await FirebaseMessaging.instance.getInitialMessage(),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// sos_id mỗi khi có thông báo lúc app đang mở hoặc người dùng bấm vào thông báo.
  static Stream<String> get sosAlerts => _sosAlerts.stream;

  /// sos_id của thông báo đã mở app từ trạng thái tắt (chỉ lấy được một lần).
  static String? takeInitialSosId() {
    final id = _initialSosId;
    _initialSosId = null;
    return id;
  }

  /// Xin quyền thông báo và lưu token cho tài khoản đang đăng nhập.
  static Future<void> register() async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);
      _tokenSubscription ??= messaging.onTokenRefresh.listen(_saveToken);
    } catch (_) {
      // Không có thông báo đẩy vẫn dùng được app.
    }
  }

  /// Gọi trước khi đăng xuất để máy này ngừng nhận SOS của tài khoản cũ.
  static Future<void> unregister() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (supabase.auth.currentUser == null) return;
    try {
      await supabase
          .rpc('set_fcm_token', params: {'p_token': null})
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<void> _saveToken(String token) async {
    if (supabase.auth.currentUser == null) return;
    try {
      await supabase.rpc('set_fcm_token', params: {'p_token': token});
    } catch (_) {}
  }

  static void _emit(RemoteMessage message) {
    final id = _sosId(message);
    if (id != null) _sosAlerts.add(id);
  }

  static String? _sosId(RemoteMessage? message) {
    final id = message?.data['sos_id']?.toString() ?? '';
    return id.isEmpty ? null : id;
  }
}
