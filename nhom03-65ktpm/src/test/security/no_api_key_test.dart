import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kiểm tra tiêu chí 4 của issue #12: **không lộ API key** trong app.
///
/// App chỉ được biết địa chỉ máy chủ trung gian; khoá Gemini nằm ở server.
/// Test quét toàn bộ `lib/` để chặn trường hợp vô tình dán khoá vào code.
void main() {
  test('không có Google API key trong mã nguồn app', () {
    final violations = _scan(<RegExp>[
      RegExp(r'AIza[0-9A-Za-z_\-]{35}'),
      RegExp(r'x-goog-api-key', caseSensitive: false),
      RegExp(r'generativelanguage\.googleapis\.com', caseSensitive: false),
    ]);

    expect(
      violations,
      isEmpty,
      reason:
          'Khoá Gemini/Google không được nằm trong app. Chỉ cấu hình '
          'AI_SUMMARY_ENDPOINT trỏ tới máy chủ trung gian.',
    );
  });

  test('không nhúng service_role key của Supabase', () {
    final violations = _scan(<RegExp>[
      RegExp(r'service_role', caseSensitive: false),
    ]);

    expect(
      violations,
      isEmpty,
      reason: 'App chỉ dùng anon key; service_role chỉ dành cho server.',
    );
  });
}

List<String> _scan(List<RegExp> patterns) {
  final matches = <String>[];
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    return matches;
  }
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final content = entity.readAsStringSync();
    if (patterns.any((RegExp pattern) => pattern.hasMatch(content))) {
      matches.add(entity.path);
    }
  }
  return matches;
}
