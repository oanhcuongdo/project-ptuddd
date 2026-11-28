import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hỗ trợ UC-05: Gọi điện nhanh Hotline tới tiệm sửa xe hoặc cây xăng.
class CallHelper {
  CallHelper._();

  /// Chuẩn hóa chuỗi số điện thoại bằng cách loại bỏ khoảng trắng và ký tự không phải số/+
  static String cleanPhone(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '').trim();
  }

  /// Kích hoạt trình gọi điện mặc định của thiết bị qua URL Scheme `tel:`
  static Future<bool> makeCall(BuildContext context, String? phone) async {
    final cleaned = cleanPhone(phone);

    if (cleaned.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiệm hiện chưa cập nhật số điện thoại liên hệ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        return await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thiết bị không hỗ trợ tính năng cuộc gọi trực tiếp'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return false;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể kích hoạt cuộc gọi. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }
  }
}
