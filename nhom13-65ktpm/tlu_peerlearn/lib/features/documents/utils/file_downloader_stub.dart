import 'dart:typed_data';

/// Fallback stubs for unsupported platforms.
Future<bool> downloadFileFromUrl({
  required String url,
  required String fileName,
}) async {
  return false;
}

Future<bool> openFileInBrowser(String url) async {
  return false;
}

Future<Uint8List?> inflateRawBytes(Uint8List compressed) async {
  return null;
}
