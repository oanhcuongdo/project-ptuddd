import 'lessons.dart';

/// Tổng kết một phiên luyện tập: số lượt, điểm trung bình và những mục lần đầu
/// đạt [masteryScore] trong phiên này.
class SessionSummary {
  int _count = 0;
  int _sum = 0;
  final Set<String> newlyMastered = {};

  int get attempts => _count;
  double get average => _count == 0 ? 0 : _sum / _count;

  /// [bestBeforeSession] là điểm cao nhất của mục TRƯỚC khi phiên bắt đầu.
  void add(String item, int score, int bestBeforeSession) {
    _count++;
    _sum += score;
    if (bestBeforeSession < masteryScore && score >= masteryScore) newlyMastered.add(item);
  }
}
