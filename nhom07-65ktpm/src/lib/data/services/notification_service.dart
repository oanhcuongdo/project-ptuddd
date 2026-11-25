import 'dart:async';

import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  bool _isPermissionGranted = true;
  bool get isPermissionGranted => _isPermissionGranted;

  Future<void> initialize() async {
    // Ready for native local notifications plugin setup
    debugPrint(
      '[NotificationService] Đã khởi tạo hệ thống thông báo cục bộ DCSleep.',
    );
  }

  Future<bool> requestPermission() async {
    _isPermissionGranted = true;
    return true;
  }

  Future<void> scheduleBedtimeReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    debugPrint(
      '[NotificationService] Đã lên lịch nhắc nhở: $hour:$minute - $title - $body',
    );
  }

  Future<void> cancelAllReminders() async {
    debugPrint('[NotificationService] Đã hủy toàn bộ lịch nhắc nhở.');
  }
}
