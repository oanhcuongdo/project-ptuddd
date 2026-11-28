import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sos_rules.dart';

/// Mở trình gọi điện với số đã điền sẵn.
Future<void> launchPhoneCall(BuildContext context, String phone) async {
  final ok = await _launch(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  if (!ok && context.mounted) {
    _showError(context, 'Không mở được trình gọi điện trên thiết bị này.');
  }
}

/// Mở Google Maps chỉ đường tới điểm sự cố.
Future<void> launchDirections(
  BuildContext context,
  double latitude,
  double longitude,
) async {
  final ok = await _launch(
    directionsUri(latitude, longitude),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    _showError(context, 'Không mở được Google Maps trên thiết bị này.');
  }
}

/// launchUrl có thể ném lỗi thay vì trả false khi không có ứng dụng phù hợp.
Future<bool> _launch(
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  try {
    return await launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
