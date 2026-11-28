import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../services/proof_image_storage_service.dart';

/// Widget xem trước ảnh minh chứng (Sprint 2):
/// Hiển thị ảnh chụp, mốc thời gian, vị trí check-in, thông tin tệp lưu cục bộ
/// và hỗ trợ phóng to toàn màn hình hoặc xóa/chụp lại.
class ProofImagePreviewCard extends StatelessWidget {
  const ProofImagePreviewCard({
    super.key,
    required this.storedImage,
    required this.locationLabel,
    required this.onRetakeCamera,
    required this.onPickGallery,
    required this.onRemoveImage,
  });

  final StoredProofImage? storedImage;
  final String locationLabel;
  final VoidCallback? onRetakeCamera;
  final VoidCallback? onPickGallery;
  final VoidCallback? onRemoveImage;

  void _showFullScreenPreview(BuildContext context, StoredProofImage img) {
    if (kIsWeb) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.file(
                  File(img.savedPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton.filled(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Đóng xem trước',
              ),
            ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tệp: ${img.fileName} (${img.formattedSize})\nĐường dẫn lưu: ${img.savedPath}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = storedImage;
    final timeFormat = DateFormat('HH:mm:ss - dd/MM/yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_back_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '2. Chụp & Xem trước ảnh minh chứng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (img != null)
                  TextButton.icon(
                    onPressed: onRemoveImage,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Xóa ảnh',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (img == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có ảnh minh chứng thực tế',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hãy chụp ảnh bàn học kèm đồng hồ, lớp gia sư hoặc bài tập đã hoàn thành. Ảnh sẽ được nén (1280px, 80%) và lưu an toàn vào bộ nhớ máy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Container(
                                height: 220,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: Text('Ảnh đã chọn: ${img.fileName}'),
                              )
                            : Image.file(
                                File(img.savedPath),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      if (!kIsWeb)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filledTonal(
                            onPressed: () =>
                                _showFullScreenPreview(context, img),
                            icon: const Icon(Icons.zoom_out_map),
                            tooltip: 'Phóng to xem chi tiết ảnh',
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeFormat.format(img.savedAt),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Đã nén: ${img.formattedSize}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (locationLabel.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        locationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_copy_outlined,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đã lưu vào bộ nhớ máy: ${img.savedPath}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRetakeCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(img == null ? 'Chụp Camera' : 'Chụp lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn từ máy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
