import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Metadata của tệp ảnh sao kê / uỷ nhiệm chi sau khi được lưu trữ cục bộ.
class StoredReceiptImage {
  const StoredReceiptImage({
    required this.savedPath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.savedAt,
  });

  /// Đường dẫn lưu trữ lâu dài của ảnh chứng từ giải ngân.
  final String savedPath;

  /// Tên tệp chuẩn hóa (vd: receipt_1763548200000.jpg).
  final String fileName;

  /// Dung lượng tệp tính bằng byte.
  final int fileSizeBytes;

  /// Thời điểm lưu trữ chứng từ.
  final DateTime savedAt;

  /// Định dạng dung lượng thân thiện (KB / MB).
  String get formattedSize =>
      DisbursementReceiptStorageService.formatBytes(fileSizeBytes);
}

/// Dịch vụ quản lý lưu trữ ảnh sao kê / chuyển khoản giải ngân từ thiện cục bộ.
/// Sao chép ảnh từ thư mục tạm của Camera/Gallery vào thư mục bền vững của ứng dụng
/// để đảm bảo chứng từ không bị hệ điều hành xoá mất khi dọn bộ nhớ đệm.
class DisbursementReceiptStorageService {
  const DisbursementReceiptStorageService();

  static const String _receiptFolderName = 'disbursement_receipts';

  /// Định dạng dung lượng byte sang KB / MB dễ đọc.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  /// Lấy (hoặc tự động tạo mới) thư mục lưu ảnh sao kê giải ngân của ứng dụng.
  Future<Directory> getReceiptStorageDirectory() async {
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

    final receiptDir = Directory(p.join(baseDirPath, _receiptFolderName));
    if (!await receiptDir.exists()) {
      await receiptDir.create(recursive: true);
    }
    return receiptDir;
  }

  /// Sao chép tệp ảnh chứng từ từ đường dẫn tạm vào thư mục lưu trữ bền vững.
  /// Trên Web (blob URL / memory path), giữ nguyên đường dẫn hợp lệ để hiển thị.
  Future<StoredReceiptImage> saveReceiptImage(
    String sourcePath, {
    String? disbursementRef,
  }) async {
    final now = DateTime.now();
    final safeRef = (disbursementRef ?? '')
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath).toLowerCase()
        : '.jpg';
    final prefix = safeRef.isNotEmpty ? 'receipt_${safeRef}_' : 'receipt_';
    final fileName = '$prefix${now.millisecondsSinceEpoch}$ext';

    // Môi trường Web không có hệ thống tệp cục bộ -> giữ nguyên đường dẫn blob/network
    if (kIsWeb) {
      return StoredReceiptImage(
        savedPath: sourcePath,
        fileName: fileName,
        fileSizeBytes: 0,
        savedAt: now,
      );
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return StoredReceiptImage(
        savedPath: sourcePath,
        fileName: p.basename(sourcePath),
        fileSizeBytes: 0,
        savedAt: now,
      );
    }

    final storageDir = await getReceiptStorageDirectory();
    final destinationPath = p.join(storageDir.path, fileName);
    final copiedFile = await sourceFile.copy(destinationPath);
    final fileSize = await copiedFile.length();

    return StoredReceiptImage(
      savedPath: copiedFile.path,
      fileName: fileName,
      fileSizeBytes: fileSize,
      savedAt: now,
    );
  }

  /// Xoá tệp ảnh chứng từ cục bộ khi người dùng gỡ bỏ ảnh trước khi lập phiếu chi.
  Future<bool> deleteReceiptImage(String path) async {
    if (kIsWeb || path.isEmpty) return false;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('[DisbursementReceiptStorageService] Không thể xoá tệp: $e');
    }
    return false;
  }
}
