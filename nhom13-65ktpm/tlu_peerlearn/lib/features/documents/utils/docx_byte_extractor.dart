import 'dart:convert';
import 'dart:typed_data';
import 'docx_xml_parser.dart';
import 'file_downloader.dart';
import 'text_extractor.dart';

/// Pure-Dart extractor for `.docx` ZIP archives (`word/document.xml`)
/// with zero external package dependencies.
class DocxByteExtractor {
  /// Extracts clean text (up to 15,000 chars per BR-04) from raw `.docx` bytes.
  static Future<String> extractTextFromDocxBytes(Uint8List bytes) async {
    if (bytes.length < 22) return '';

    final data = ByteData.sublistView(bytes);
    // 1. Locate End of Central Directory record (signature 0x06054b50)
    int eocdOffset = -1;
    final minOffset = bytes.length > 65557 ? bytes.length - 65557 : 0;
    for (int i = bytes.length - 22; i >= minOffset; i--) {
      if (data.getUint32(i, Endian.little) == 0x06054b50) {
        eocdOffset = i;
        break;
      }
    }
    if (eocdOffset == -1) return '';

    final cdSize = data.getUint32(eocdOffset + 12, Endian.little);
    final cdOffset = data.getUint32(eocdOffset + 16, Endian.little);
    if (cdOffset + cdSize > bytes.length) return '';

    // 2. Scan Central Directory entries (signature 0x02014b50) for word/document.xml
    int cursor = cdOffset;
    final cdEnd = cdOffset + cdSize;
    while (cursor + 46 <= cdEnd) {
      if (data.getUint32(cursor, Endian.little) != 0x02014b50) break;

      final compressionMethod = data.getUint16(cursor + 10, Endian.little);
      final compressedSize = data.getUint32(cursor + 20, Endian.little);
      final nameLength = data.getUint16(cursor + 28, Endian.little);
      final extraLength = data.getUint16(cursor + 30, Endian.little);
      final commentLength = data.getUint16(cursor + 32, Endian.little);
      final localHeaderOffset = data.getUint32(cursor + 42, Endian.little);

      if (cursor + 46 + nameLength > bytes.length) break;
      final entryName = utf8.decode(
        bytes.sublist(cursor + 46, cursor + 46 + nameLength),
        allowMalformed: true,
      );

      if (entryName == 'word/document.xml') {
        if (localHeaderOffset + 30 > bytes.length) return '';
        if (data.getUint32(localHeaderOffset, Endian.little) != 0x04034b50) {
          return '';
        }
        final localNameLen = data.getUint16(localHeaderOffset + 26, Endian.little);
        final localExtraLen = data.getUint16(localHeaderOffset + 28, Endian.little);
        final dataStart = localHeaderOffset + 30 + localNameLen + localExtraLen;
        final dataEnd = dataStart + compressedSize;
        if (dataEnd > bytes.length) return '';

        final rawPayload = bytes.sublist(dataStart, dataEnd);
        Uint8List? xmlBytes;
        if (compressionMethod == 0) {
          xmlBytes = rawPayload;
        } else if (compressionMethod == 8) {
          xmlBytes = await inflateRawBytes(rawPayload);
        }

        if (xmlBytes == null || xmlBytes.isEmpty) return '';
        final xmlString = utf8.decode(xmlBytes, allowMalformed: true);
        final parsed = DocxXmlParser.extractTextFromXml(xmlString);
        return TextExtractor.truncateToLimit(TextExtractor.cleanText(parsed));
      }

      cursor += 46 + nameLength + extraLength + commentLength;
    }

    return '';
  }
}
