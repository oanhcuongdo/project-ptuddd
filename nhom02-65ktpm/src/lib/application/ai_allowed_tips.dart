import '../domain/entities/tip.dart';
import '../domain/enums.dart';
import '../domain/rules/tip_selector.dart';
import 'tips_cache.dart';

/// Danh sách gợi ý AI được phép chọn: tip đang bật và phù hợp mục tiêu.
/// Nếu chưa có tip nào cho mục tiêu thì cho phép toàn bộ tip đang bật.
List<Tip> allowedTipsForAi(TipsCache cache, Goal goal) {
  final forGoal = TipSelector.forGoal(cache.tips, goal);
  return forGoal.isNotEmpty ? forGoal : cache.tips.where((t) => t.active).toList();
}
