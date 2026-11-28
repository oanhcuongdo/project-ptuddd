import '../entities/tip.dart';

abstract class TipRepository {
  /// Các gợi ý đang bật (`active == true`) trong thư viện `tips`.
  Future<List<Tip>> fetchActiveTips();
}
