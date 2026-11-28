import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Downloads a file from [url] and lets the user save it via native save dialog.
Future<bool> downloadFileFromUrl({
  required String url,
  required String fileName,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final chunks = <int>[];
    await for (final chunk in response) {
      chunks.addAll(chunk);
    }
    final bytes = Uint8List.fromList(chunks);

    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Lưu tài liệu',
      fileName: fileName,
      bytes: bytes,
    );
    if (savedUri != null) {
      if (savedUri.scheme == 'file') {
        final file = File.fromUri(savedUri);
        if (!await file.exists()) {
          await file.writeAsBytes(bytes);
        }
      }
      return true;
    }
    return false;
  } finally {
    client.close();
  }
}

/// Opens a file URL using OS default handler on desktop platforms.
Future<bool> openFileInBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;

  try {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
      return true;
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
      return true;
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
      return true;
    }
  } catch (_) {}
  return false;
}

/// Decompresses raw DEFLATE bytes (used by ZIP / DOCX entries) via dart:io ZLibDecoder.
Future<Uint8List?> inflateRawBytes(Uint8List compressed) async {
  try {
    return Uint8List.fromList(ZLibDecoder(raw: true).convert(compressed));
  } catch (_) {
    return null;
  }
}
