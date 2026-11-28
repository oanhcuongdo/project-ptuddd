import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Chỉ ở bản debug và khi bật `DEV_TRUST_SELF_SIGNED`: chấp nhận chứng chỉ
/// tự ký, và chỉ cho đúng host của API (không mở cho mọi trang).
void installDevHttpOverrides(String apiBaseUrl) {
  if (!kDebugMode || !AppConfig.devTrustSelfSigned) return;
  final host = Uri.tryParse(apiBaseUrl)?.host;
  if (host == null || host.isEmpty) return;
  HttpOverrides.global = _TrustApiHost(host);
}

class _TrustApiHost extends HttpOverrides {
  _TrustApiHost(this.host);

  final String host;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, certHost, port) => certHost == host;
  }
}
