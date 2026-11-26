// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Mở phòng Jitsi Meet trong tab trình duyệt mới (khi người dùng muốn toàn màn hình)
void openMeetInNewTab(String url) {
  html.window.open(url, '_blank');
}

/// Nhúng trực tiếp phòng Video Call Jitsi Meet vào giao diện Chrome Web bằng `HtmlElementView` (iframe).
/// Hỗ trợ đầy đủ Camera, Micro, Chia sẻ màn hình & Toàn màn hình y hệt Google Meet.
class JitsiMeetFrame extends StatefulWidget {
  final String meetUrl;
  final String roomTitle;

  const JitsiMeetFrame({
    super.key,
    required this.meetUrl,
    required this.roomTitle,
  });

  @override
  State<JitsiMeetFrame> createState() => _JitsiMeetFrameState();
}

class _JitsiMeetFrameState extends State<JitsiMeetFrame> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'buddytalk-jitsi-${DateTime.now().microsecondsSinceEpoch}-${widget.meetUrl.hashCode}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.meetUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'camera; microphone; fullscreen; display-capture; autoplay; clipboard-write'
        ..allowFullscreen = true;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
