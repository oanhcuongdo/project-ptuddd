import '../core/result.dart';
import '../core/strings/scan_strings.dart';
import '../data/ai/ai_analysis_service.dart';
import '../domain/entities/food_item.dart';
import 'ai_allowed_tips.dart';
import 'analyze_meal_photo.dart';
import 'session_service.dart';
import 'tip_resolver.dart';
import 'tips_cache.dart';

/// Use case: Người dùng gõ tên món -> AI đánh giá 1 món (chỉ văn bản).
/// Nếu AI lỗi, UI cho người dùng tự chọn mức độ bằng chip.
class AnalyzeFoodText {
  AnalyzeFoodText(this._ai, this._tipsCache, this._tipResolver, this._session);

  final AiAnalysisService _ai;
  final TipsCache _tipsCache;
  final TipResolver _tipResolver;
  final SessionService _session;

  Future<Result<FoodItem>> call(String dishName) async {
    if (dishName.trim().isEmpty) {
      return const Err(AppFailure(FailureType.invalidResponse, ScanStrings.textNameRequired));
    }
    await _tipsCache.ensureLoaded();
    final result = await _ai.analyzeFoodText(
      dishName,
      goal: _session.goal,
      allowedTips: allowedTipsForAi(_tipsCache, _session.goal),
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        return switch (AnalyzeMealPhoto.toItems(value, _tipResolver)) {
          Ok(:final value) => Ok(value.first),
          Err(:final failure) => Err(failure),
        };
    }
  }
}
