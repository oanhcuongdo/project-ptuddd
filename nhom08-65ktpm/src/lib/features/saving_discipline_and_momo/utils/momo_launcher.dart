import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared helper to launch the native MoMo app with clipboard & fallback support.
class MoMoLauncher {
  const MoMoLauncher._();

  /// Attempts to open the MoMo app directly.
  ///
  /// Copies [copySummary] (e.g. phone number / transfer note) to clipboard first
  /// so the user can immediately paste it inside MoMo.
  /// Returns `true` if an external app or link was launched.
  static Future<bool> openMoMo(
    BuildContext context, {
    String? deeplink,
    String? copySummary,
  }) async {
    if (copySummary != null && copySummary.trim().isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: copySummary.trim()));
    }

    final trimmedLink = deeplink?.trim() ?? '';
    final parsedLink = trimmedLink.isNotEmpty ? Uri.tryParse(trimmedLink) : null;

    // 1. If it's already a momo:// deeplink, launch it directly.
    if (parsedLink != null && parsedLink.scheme.toLowerCase() == 'momo') {
      if (await _tryLaunch(parsedLink, LaunchMode.externalApplication)) {
        return true;
      }
    }

    // 2. If it's an https:// MoMo link, try forcing non-browser app handling first.
    if (parsedLink != null &&
        (parsedLink.scheme.toLowerCase() == 'https' ||
            parsedLink.scheme.toLowerCase() == 'http')) {
      if (await _tryLaunch(parsedLink, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }
    }

    // 3. Try opening the MoMo app directly via its native URI schemes.
    for (final schemeUri in [
      Uri.parse('momo://app'),
      Uri.parse('momo://'),
    ]) {
      if (await _tryLaunch(schemeUri, LaunchMode.externalApplication)) {
        return true;
      }
    }

    // 4. Last resort: open the https:// MoMo web link in the browser if available.
    if (parsedLink != null &&
        (parsedLink.scheme.toLowerCase() == 'https' ||
            parsedLink.scheme.toLowerCase() == 'http')) {
      if (await _tryLaunch(parsedLink, LaunchMode.externalApplication)) {
        return true;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy ứng dụng MoMo trên thiết bị. Đã sao chép thông tin chuyển khoản.',
          ),
        ),
      );
    }
    return false;
  }

  static Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}
