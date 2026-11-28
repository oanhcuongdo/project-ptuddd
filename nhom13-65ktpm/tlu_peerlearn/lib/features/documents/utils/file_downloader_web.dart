import 'dart:js_interop';
import 'dart:typed_data';

@JS('document.createElement')
external _AnchorElement _createElement(String tagName);

@JS('document.body.appendChild')
external void _appendChild(_AnchorElement element);

extension type _AnchorElement(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external set target(String value);
  external set rel(String value);
  external void click();
  external void remove();
}

@JS('DecompressionStream')
extension type _DecompressionStream._(JSObject _) implements JSObject {
  external factory _DecompressionStream(String format);
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts);
  external _ReadableStream stream();
}

extension type _ReadableStream(JSObject _) implements JSObject {
  external _ReadableStream pipeThrough(_DecompressionStream stream);
}

@JS('Response')
extension type _Response._(JSObject _) implements JSObject {
  external factory _Response(_ReadableStream body);
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

/// Triggers a real browser file download using a temporary anchor element.
/// Appends `?download=<fileName>` for Supabase Storage URLs so the browser
/// receives `Content-Disposition: attachment` and saves the file directly.
Future<bool> downloadFileFromUrl({
  required String url,
  required String fileName,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;

  final downloadUri = uri.path.contains('/storage/v1/object/')
      ? uri.replace(
          queryParameters: {
            ...uri.queryParameters,
            'download': fileName,
          },
        )
      : uri;

  final anchor = _createElement('a')
    ..href = downloadUri.toString()
    ..download = fileName
    ..target = '_blank'
    ..rel = 'noopener noreferrer';

  _appendChild(anchor);
  anchor.click();
  anchor.remove();
  return true;
}

/// Opens a file URL directly in a new browser tab (ideal for viewing PDFs natively).
Future<bool> openFileInBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;

  final anchor = _createElement('a')
    ..href = uri.toString()
    ..target = '_blank'
    ..rel = 'noopener noreferrer';

  _appendChild(anchor);
  anchor.click();
  anchor.remove();
  return true;
}

/// Decompresses raw DEFLATE bytes (used by ZIP / DOCX entries) via browser DecompressionStream.
Future<Uint8List?> inflateRawBytes(Uint8List compressed) async {
  try {
    final blob = _Blob([compressed.toJS].toJS);
    final stream = blob.stream().pipeThrough(_DecompressionStream('deflate-raw'));
    final buffer = await _Response(stream).arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    return null;
  }
}
