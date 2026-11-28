export 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart';
