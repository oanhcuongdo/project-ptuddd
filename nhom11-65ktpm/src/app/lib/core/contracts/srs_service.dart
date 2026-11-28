import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_implementation.dart';
import 'lesson_repository.dart';
import 'models/lesson.dart';

/// Kho thẻ ôn tập SM-2. Chủ sở hữu: **Hoa** (#20).
///
/// Người dùng khác: Trang chủ (#31) hiện [dueCount]; Bài học (#19) gọi [addWords]
/// khi học xong bài; Huy hiệu (#21) đếm từ đã thuộc qua sự kiện `srs_review`.
abstract class SrsService {
  /// Số thẻ cần ôn hôm nay.
  Future<int> dueCount();

  /// Các từ cần ôn hôm nay (tối đa [limit]).
  Future<List<Word>> dueWords({int limit = 20});

  /// Thêm từ vào kho thẻ (bỏ qua từ đã có).
  Future<void> addWords(Iterable<Word> words);
}

final srsServiceProvider = Provider<SrsService>((ref) {
  return FakeSrsService(ref.watch(lessonRepositoryProvider));
});

/// Bản giả: coi mọi từ của 2 bài đầu là "đã học", một nửa đến hạn hôm nay.
class FakeSrsService with FakeImplementation implements SrsService {
  final LessonRepository _lessons;
  final _added = <String, Word>{};

  FakeSrsService(this._lessons);

  Future<List<Word>> _due() async {
    final all = await _lessons.lessons();
    final learned = [for (final l in all.take(2)) ...l.words, ..._added.values];
    final unique = {for (final w in learned) w.key: w}.values.toList();
    return [for (var i = 0; i < unique.length; i++) if (i.isEven) unique[i]];
  }

  @override
  Future<int> dueCount() async => (await _due()).length;

  @override
  Future<List<Word>> dueWords({int limit = 20}) async => (await _due()).take(limit).toList();

  @override
  Future<void> addWords(Iterable<Word> words) async {
    for (final w in words) {
      _added[w.key] = w;
    }
  }
}
