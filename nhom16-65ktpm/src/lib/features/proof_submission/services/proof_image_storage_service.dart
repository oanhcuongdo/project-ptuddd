import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Thông tin tệp ảnh minh chứng sau khi đã được sao chép và lưu trữ vào bộ nhớ máy.
class StoredProofImage {
  const StoredProofImage({
    required this.savedPath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.savedAt,
  });

  /// Đường dẫn tuyệt đối của tệp ảnh trong bộ nhớ cục bộ của ứng dụng.
  final String savedPath;

  /// Tên tệp ảnh đã chuẩn hóa (vd: proof_1763548200000.jpg).
  final String fileName;

  /// Dung lượng tệp ảnh tính bằng byte sau khi nén.
  final int fileSizeBytes;

  /// Thời điểm lưu ảnh vào bộ nhớ máy.
  final DateTime savedAt;

  /// Hiển thị dung lượng tệp dễ đọc (KB / MB).
  String get formattedSize =>
      ProofImageStorageService.formatBytes(fileSizeBytes);
}

/// Kết quả kiểm tra tính toàn vẹn và dung lượng của tệp ảnh lưu cục bộ (Sprint 3 - Giai đoạn 5).
class ImageIntegrityResult {
  const ImageIntegrityResult({
    required this.isValid,
    this.message,
    this.warningMessage,
  });

  final bool isValid;
  final String? message;
  final String? warningMessage;
}

/// Thống kê trạng thái thư mục lưu trữ ảnh minh chứng trên bộ nhớ thiết bị.
class ProofStorageStats {
  const ProofStorageStats({
    required this.directoryPath,
    required this.imageCount,
    required this.totalSizeBytes,
  });

  final String directoryPath;
  final int imageCount;
  final int totalSizeBytes;

  String get formattedTotalSize =>
      ProofImageStorageService.formatBytes(totalSizeBytes);
}

/// Dịch vụ quản lý lưu trữ tệp ảnh minh chứng cục bộ an toàn (Sprint 2 - Sprint 3).
class ProofImageStorageService {
  const ProofImageStorageService();

  static const String _proofFolderName = 'proof_images';
  static const int minRecommendedImageBytes = 2 * 1024; // 2 KB
  static const int maxAllowedImageBytes = 15 * 1024 * 1024; // 15 MB

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  /// Lấy thư mục lưu trữ ảnh minh chứng riêng của ứng dụng trên bộ nhớ thiết bị.
  Future<Directory> getProofStorageDirectory() async {
    String baseDirPath;
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final dbPath = await getDatabasesPath();
        baseDirPath = p.dirname(dbPath);
      } else {
        baseDirPath = Directory.systemTemp.path;
      }
    } catch (_) {
      baseDirPath = Directory.systemTemp.path;
    }

    final proofDir = Directory(p.join(baseDirPath, _proofFolderName));
    if (!await proofDir.exists()) {
      await proofDir.create(recursive: true);
    }
    return proofDir;
  }

  /// Sao chép ảnh từ đường dẫn tạm của Camera/Gallery vào bộ nhớ lưu trữ lâu dài của máy.
  Future<StoredProofImage> saveImageToLocalStorage(
    String sourcePath, {
    String? challengeId,
  }) async {
    final now = DateTime.now();
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final prefix = (challengeId != null && challengeId.isNotEmpty)
        ? 'proof_${challengeId}_'
        : 'proof_';
    final fileName = '$prefix${now.millisecondsSinceEpoch}$ext';

    if (kIsWeb) {
      return StoredProofImage(
        savedPath: sourcePath,
        fileName: fileName,
        fileSizeBytes: 0,
        savedAt: now,
      );
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Không tìm thấy tệp ảnh gốc để lưu trữ',
        sourcePath,
      );
    }

    final storageDir = await getProofStorageDirectory();
    final destinationPath = p.join(storageDir.path, fileName);
    final savedFile = await sourceFile.copy(destinationPath);
    final sizeBytes = await savedFile.length();

    return StoredProofImage(
      savedPath: savedFile.path,
      fileName: fileName,
      fileSizeBytes: sizeBytes,
      savedAt: now,
    );
  }

  /// Kiểm tra tính hợp lệ của tệp ảnh minh chứng trước khi gửi hồ sơ (Sprint 3 - Giai đoạn 5).
  Future<ImageIntegrityResult> verifyImageIntegrity(
    StoredProofImage? storedImage,
  ) async {
    if (storedImage == null || kIsWeb) {
      return const ImageIntegrityResult(isValid: true);
    }

    final file = File(storedImage.savedPath);
    if (!await file.exists()) {
      return const ImageIntegrityResult(
        isValid: false,
        message:
            'Không tìm thấy tệp ảnh minh chứng trong bộ nhớ máy. Vui lòng chụp hoặc chọn lại ảnh.',
      );
    }

    final length = await file.length();
    if (length <= 0) {
      return const ImageIntegrityResult(
        isValid: false,
        message: 'Tệp ảnh minh chứng bị rỗng (0 KB). Vui lòng chụp lại ảnh.',
      );
    }

    if (length > maxAllowedImageBytes) {
      return ImageIntegrityResult(
        isValid: false,
        message:
            'Dung lượng ảnh (${formatBytes(length)}) vượt quá giới hạn 15 MB.',
      );
    }

    if (length < minRecommendedImageBytes) {
      return ImageIntegrityResult(
        isValid: true,
        warningMessage:
            'Dung lượng tệp ảnh rất nhỏ (${formatBytes(length)}), ảnh có thể bị mờ hoặc độ phân giải thấp.',
      );
    }

    return const ImageIntegrityResult(isValid: true);
  }

  /// Thống kê số lượng và tổng dung lượng các tệp ảnh minh chứng đang lưu trong bộ nhớ máy.
  Future<ProofStorageStats> getStorageStats() async {
    if (kIsWeb) {
      return const ProofStorageStats(
        directoryPath: 'web://local_storage/proof_images',
        imageCount: 0,
        totalSizeBytes: 0,
      );
    }
    try {
      final dir = await getProofStorageDirectory();
      var count = 0;
      var totalBytes = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          count++;
          totalBytes += await entity.length();
        }
      }
      return ProofStorageStats(
        directoryPath: dir.path,
        imageCount: count,
        totalSizeBytes: totalBytes,
      );
    } catch (_) {
      return const ProofStorageStats(
        directoryPath: 'proof_images/',
        imageCount: 0,
        totalSizeBytes: 0,
      );
    }
  }

  /// Xóa tệp ảnh minh chứng đã lưu khỏi bộ nhớ máy (khi người dùng chọn chụp lại).
  Future<bool> deleteStoredImage(String? savedPath) async {
    if (savedPath == null || savedPath.isEmpty || kIsWeb) return false;
    try {
      final file = File(savedPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
