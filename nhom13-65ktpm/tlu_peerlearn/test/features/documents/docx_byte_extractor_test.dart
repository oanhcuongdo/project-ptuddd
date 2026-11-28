import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_peerlearn/features/documents/utils/docx_byte_extractor.dart';

Uint8List _buildMinimalStoredZip(String entryName, String content) {
  final nameBytes = utf8.encode(entryName);
  final dataBytes = utf8.encode(content);
  final localHeader = BytesBuilder();

  // Local file header
  final lfh = ByteData(30);
  lfh.setUint32(0, 0x04034b50, Endian.little);
  lfh.setUint16(4, 20, Endian.little); // version
  lfh.setUint16(8, 0, Endian.little); // stored (method 0)
  lfh.setUint32(18, dataBytes.length, Endian.little); // compressed size
  lfh.setUint32(22, dataBytes.length, Endian.little); // uncompressed size
  lfh.setUint16(26, nameBytes.length, Endian.little);
  localHeader.add(lfh.buffer.asUint8List());
  localHeader.add(nameBytes);
  localHeader.add(dataBytes);

  final cdOffset = localHeader.length;
  final cd = BytesBuilder();
  final cdh = ByteData(46);
  cdh.setUint32(0, 0x02014b50, Endian.little);
  cdh.setUint16(10, 0, Endian.little); // stored
  cdh.setUint32(20, dataBytes.length, Endian.little);
  cdh.setUint32(24, dataBytes.length, Endian.little);
  cdh.setUint16(28, nameBytes.length, Endian.little);
  cdh.setUint32(42, 0, Endian.little); // local header offset
  cd.add(cdh.buffer.asUint8List());
  cd.add(nameBytes);

  final cdBytes = cd.toBytes();
  final eocd = ByteData(22);
  eocd.setUint32(0, 0x06054b50, Endian.little);
  eocd.setUint16(8, 1, Endian.little);
  eocd.setUint16(10, 1, Endian.little);
  eocd.setUint32(12, cdBytes.length, Endian.little);
  eocd.setUint32(16, cdOffset, Endian.little);

  final out = BytesBuilder()
    ..add(localHeader.toBytes())
    ..add(cdBytes)
    ..add(eocd.buffer.asUint8List());
  return out.toBytes();
}

void main() {
  test('DocxByteExtractor extracts text from word/document.xml inside docx archive', () async {
    const xml = '<w:document><w:body><w:p><w:r><w:t>Kiểm thử bảo mật SQLi</w:t></w:r></w:p></w:body></w:document>';
    final zipBytes = _buildMinimalStoredZip('word/document.xml', xml);

    final extracted = await DocxByteExtractor.extractTextFromDocxBytes(zipBytes);
    expect(extracted, 'Kiểm thử bảo mật SQLi');
  });

  test('DocxByteExtractor returns empty string for invalid bytes', () async {
    final extracted = await DocxByteExtractor.extractTextFromDocxBytes(Uint8List.fromList([1, 2, 3]));
    expect(extracted, isEmpty);
  });
}
