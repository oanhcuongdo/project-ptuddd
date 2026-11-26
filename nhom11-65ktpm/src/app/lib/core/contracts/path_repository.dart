import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fakes/fake_path_repository.dart';
import 'lesson_repository.dart';
import 'models/learning_event.dart';
import 'models/path.dart';
import 'progress_service.dart';

/// Hợp đồng Lộ trình học (Bảo #29). Trang chủ (#31) gọi `loadPath()` rồi
/// `PathMap.nextNode()`.
abstract class PathRepository {
  Future<PathMap> loadPath();
}

/// Mặc định trả bản giả (tính từ bài học + sự kiện). Provider theo dõi
/// `learningEventsProvider` nên bản đồ tự cập nhật khi có sự kiện mới.
///
/// Khi có bản thật:
/// `AppConfig.fakeData ? FakePathRepository(lessons, events) : ApiPathRepository(...)`.
final pathRepositoryProvider = Provider<PathRepository>((ref) {
  final lessons = ref.watch(lessonRepositoryProvider);
  final events =
      ref.watch(learningEventsProvider).value ?? const <LearningEvent>[];
  return FakePathRepository(lessons, events);
});