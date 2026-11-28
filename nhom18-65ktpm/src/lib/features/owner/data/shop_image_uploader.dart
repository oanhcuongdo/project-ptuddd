import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../../repositories/auth_repository.dart';

class ShopImageUploader {
  static const int maxBytes = 5 * 1024 * 1024;

  Future<String> upload(XFile file) async => (await uploadWithPath(file)).url;

  Future<({String url, String path})> uploadWithPath(XFile file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Bạn cần đăng nhập lại.');
    }

    final extension = file.name.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png'}.contains(extension)) {
      throw const AppException('Chỉ chấp nhận ảnh JPG hoặc PNG.');
    }

    final data = await file.readAsBytes();
    if (data.isEmpty || data.lengthInBytes > maxBytes) {
      throw const AppException('Ảnh phải nhỏ hơn hoặc bằng 5 MB.');
    }

    final mime = extension == 'png' ? 'image/png' : 'image/jpeg';
    final name = '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    try {
      await supabase.storage
          .from('shop-images')
          .uploadBinary(
            name,
            data,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
      return (
        url: supabase.storage.from('shop-images').getPublicUrl(name),
        path: name,
      );
    } on StorageException {
      throw const AppException(
        'Tải ảnh thất bại. Kiểm tra mạng và quyền Storage.',
      );
    }
  }

  /// Dọn ảnh vừa tải nếu bước lưu hồ sơ DB thất bại.
  Future<void> remove(String path) async {
    try {
      await supabase.storage.from('shop-images').remove([path]);
    } catch (_) {}
  }
}
