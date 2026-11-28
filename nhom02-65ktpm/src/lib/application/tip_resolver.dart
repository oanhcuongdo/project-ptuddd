import '../core/constants/app_config.dart';
import '../domain/entities/food_item.dart';
import '../domain/entities/tip.dart';
import '../domain/rules/tip_selector.dart';
import 'session_service.dart';
import 'tips_cache.dart';

/// Gắn gợi ý (bản sao) cho món, dựa trên thư viện tips + mục tiêu người dùng.
class TipResolver {
  TipResolver(this._cache, this._session);

  final TipsCache _cache;
  final SessionService _session;

  Future<void> ensureLoaded() => _cache.ensureLoaded();

  /// Món nhập thủ công / ăn lại: chọn theo quy tắc `applies_to`.
  List<TipSnapshot> forManualItem(FoodItem item) {
    return TipSelector.select(
      tips: _cache.tips,
      goal: _session.goal,
      category: item.category,
      levels: item.levels,
      max: AppConfig.maxTipsForManualItem,
    ).map((t) => t.toSnapshot()).toList();
  }

  /// Món do AI phân tích: lọc mã lạ, bổ sung tối đa 1 tip, tổng <= 3.
  List<TipSnapshot> forAiCodes(List<String> codes, FoodItem item) {
    return TipSelector.resolve(
      aiCodes: codes,
      library: _cache.byCode,
      goal: _session.goal,
      category: item.category,
      levels: item.levels,
      max: AppConfig.maxTipsPerItem,
    ).map((t) => t.toSnapshot()).toList();
  }

  /// Sau khi người dùng sửa mức độ/loại món: giữ gợi ý còn phù hợp,
  /// nếu không còn gợi ý nào thì bổ sung theo quy tắc.
  List<TipSnapshot> afterEdit(FoodItem item) {
    final stillMatching = item.tips
        .map((t) => _cache.byCode[t.code])
        .whereType<Tip>()
        .where((t) => TipSelector.matches(t, item.category, item.levels))
        .map((t) => t.code)
        .toList();
    return forAiCodes(stillMatching, item);
  }
}
