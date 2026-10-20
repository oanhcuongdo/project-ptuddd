import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kiểm thử Tính Đúng đắn của Phân Tách Kiến trúc (Architectural Boundaries)', () {
    test('Tầng Database không phụ thuộc vào Flutter UI Framework', () {
      final dbDir = Directory('lib/database');
      final dartFiles = dbDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains("package:flutter/material.dart"),
          isFalse,
          reason: 'File ${file.path} trong tầng Database không được import Flutter Material UI!',
        );
        expect(
          content.contains("package:flutter/widgets.dart"),
          isFalse,
          reason: 'File ${file.path} trong tầng Database không được phụ thuộc vào Flutter Widgets!',
        );
      }
    });

    test('Tầng Domain / Business Logic không phụ thuộc vào Flutter UI Framework', () {
      final domainDir = Directory('lib/domain');
      final dartFiles = domainDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains("package:flutter/material.dart"),
          isFalse,
          reason: 'File ${file.path} trong tầng Domain không được import Flutter Material UI!',
        );
        expect(
          content.contains("package:flutter/widgets.dart"),
          isFalse,
          reason: 'File ${file.path} trong tầng Domain không được phụ thuộc vào Flutter Widgets!',
        );
      }
    });

    test('Kiểm tra cấu trúc phân lớp đầy đủ theo tiêu chuẩn Cashew', () {
      expect(Directory('lib/database/tables').existsSync(), isTrue);
      expect(Directory('lib/database/daos').existsSync(), isTrue);
      expect(Directory('lib/domain/models').existsSync(), isTrue);
      expect(Directory('lib/domain/services').existsSync(), isTrue);
      expect(Directory('lib/state').existsSync(), isTrue);
      expect(Directory('lib/ui/screens').existsSync(), isTrue);
      expect(Directory('lib/ui/widgets').existsSync(), isTrue);
    });
  });
}
