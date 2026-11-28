import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/note.dart';

class WordExportService {
  Future<String> exportNotes(List<Note> notes) async {
    if (notes.isEmpty) throw Exception('Chưa chọn ghi chú');

    final archive = Archive();
    archive
      ..addFile(ArchiveFile('[Content_Types].xml', 0, utf8.encode(_contentTypesXml)))
      ..addFile(ArchiveFile('_rels/.rels', 0, utf8.encode(_rootRelsXml)))
      ..addFile(
        ArchiveFile('word/document.xml', 0, utf8.encode(_documentXml(notes))),
      );

    final bytes = ZipEncoder().encode(archive);
    Directory directory;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${directory.path}${Platform.pathSeparator}SmartNote_$stamp.docx',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _documentXml(List<Note> notes) {
    final paragraphs = <String>[
      _paragraph('SMARTNOTE - GHI CHÚ ĐÃ XUẤT', bold: true, size: '32'),
      _paragraph(
        'Ngày xuất: ${DateTime.now().toIso8601String().substring(0, 10)}',
      ),
    ];
    for (final note in notes) {
      paragraphs
        ..add(_paragraph(note.displayTitle, bold: true, size: '28'))
        ..addAll(
          note.content
              .split('\n')
              .map((String line) => _paragraph(line.isEmpty ? ' ' : line)),
        )
        ..add(_paragraph('', size: '8'));
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>${paragraphs.join()}<w:sectPr/></w:body>
</w:document>''';
  }

  String _paragraph(String text, {bool bold = false, String size = '24'}) {
    final escaped = const HtmlEscape().convert(text);
    final b = bold ? '<w:b/>' : '';
    return '<w:p><w:r><w:rPr>$b<w:sz w:val="$size"/></w:rPr><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
  }

  static const String _contentTypesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

  static const String _rootRelsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
}
