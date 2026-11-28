import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_config.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

/// Chụp/chọn ảnh rồi nén trước khi gửi AI (cạnh dài ~1024px, JPEG ~80%).
///
/// Ảnh chỉ nằm trong bộ nhớ; file tạm của image_picker bị xóa ngay sau khi đọc.
class ImagePreparer {
  ImagePreparer([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Trả về byte JPEG đã nén, hoặc null nếu người dùng hủy.
  Future<Uint8List?> pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: AppConfig.imageMaxDimension.toDouble(),
      maxHeight: AppConfig.imageMaxDimension.toDouble(),
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: AppConfig.imageMaxDimension,
        minHeight: AppConfig.imageMaxDimension,
        quality: AppConfig.imageJpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false, // bỏ thông tin vị trí, thiết bị trong ảnh
      );
      return compressed ?? await file.readAsBytes();
    } finally {
      _deleteQuietly(file.path);
    }
  }

  /// Chỉ xóa file tạm do image_picker tạo trong thư mục cache/tmp của app,
  /// không bao giờ đụng tới ảnh gốc trong thư viện của người dùng.
  void _deleteQuietly(String path) {
    final lower = path.toLowerCase();
    if (!lower.contains('cache') && !lower.contains('tmp')) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (e) {
      debugPrint('Could not delete temp image: $e');
    }
  }
}
