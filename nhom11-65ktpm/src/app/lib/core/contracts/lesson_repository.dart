import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_implementation.dart';
import 'models/lesson.dart';

/// Nguồn bài học + từ vựng. Chủ sở hữu: **Hoa** (#18 API, #19 màn hình, #23 cache offline).
///
/// Bản giả đọc các bài mẫu trong `assets/dev/lessons/` (bản sao của `data/lessons/`).
/// Bản thật gợi ý: gọi `GET /api/lessons?since_version=` rồi cache SQLite.
abstract class LessonRepository {
  /// Mọi bài, sắp theo cấp độ rồi thứ tự.
  Future<List<Lesson>> lessons();

  Future<Lesson?> lessonById(int id);

  Future<Lesson?> lessonByCode(String code) async {
    for (final l in await lessons()) {
      if (l.code == code) return l;
    }
    return null;
  }
}

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  // Khi có bản thật: return AppConfig.fakeData ? AssetLessonRepository() : ApiLessonRepository(...);
  return AssetLessonRepository();
});

class AssetLessonRepository extends LessonRepository with FakeImplementation {
  static const _dir = 'assets/dev/lessons/';
  final AssetBundle _bundle;
  List<Lesson>? _cache;

  AssetLessonRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  @override
  Future<List<Lesson>> lessons() async {
    if (_cache != null) return _cache!;
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final files = manifest.listAssets().where((p) => p.startsWith(_dir) && p.endsWith('.json')).toList();
    final raws = <Map<String, dynamic>>[
      for (final f in files) jsonDecode(await _bundle.loadString(f)) as Map<String, dynamic>,
    ];
    raws.sort((a, b) {
      final lv = (a['level'] as String? ?? '').compareTo(b['level'] as String? ?? '');
      return lv != 0 ? lv : (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0);
    });
    // Id = thứ tự nạp, trùng với id mà seed_dev.py tạo trên CSDL mới.
    return _cache = [for (var i = 0; i < raws.length; i++) Lesson.fromJson(raws[i], id: i + 1)];
  }

  @override
  Future<Lesson?> lessonById(int id) async {
    for (final l in await lessons()) {
      if (l.id == id) return l;
    }
    return null;
  }
}
