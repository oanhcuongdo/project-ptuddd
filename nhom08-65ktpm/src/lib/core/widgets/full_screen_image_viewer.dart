import 'dart:io';

import 'package:flutter/material.dart';

/// Trình xem ảnh toàn màn hình hỗ trợ zoom/pan cho ảnh hóa đơn và minh chứng.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    this.imageUrl,
    this.filePath,
    this.title = 'Xem ảnh',
  }) : assert(imageUrl != null || filePath != null);

  final String? imageUrl;
  final String? filePath;
  final String title;

  static Future<void> open(
    BuildContext context, {
    String? imageUrl,
    String? filePath,
    String title = 'Xem ảnh',
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullScreenImageViewer(
          imageUrl: imageUrl,
          filePath: filePath,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = filePath != null
        ? Image.file(
            File(filePath!),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _errorPlaceholder(),
          )
        : Image.network(
            imageUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (_, _, _) => _errorPlaceholder(),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _errorPlaceholder() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 52, color: Colors.white70),
          SizedBox(height: 10),
          Text(
            'Không thể hiển thị ảnh.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
