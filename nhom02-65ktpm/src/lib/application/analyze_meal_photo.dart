import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../core/strings/scan_strings.dart';
import '../data/ai/ai_analysis_service.dart';
import '../data/ai/parsers/meal_response_parser.dart';
import '../domain/entities/food_item.dart';
import 'ai_allowed_tips.dart';
import 'session_service.dart';
import 'tip_resolver.dart';
import 'tips_cache.dart';

/// Use case: Quét ảnh món ăn -> danh sách món (đã gắn gợi ý) để xác nhận.
///
/// Kết quả LUÔN đi qua màn hình xác nhận, không tự lưu.
class AnalyzeMealPhoto {
  AnalyzeMealPhoto(this._ai, this._tipsCache, this._tipResolver, this._session);

  final AiAnalysisService _ai;
  final TipsCache _tipsCache;
  final TipResolver _tipResolver;
  final SessionService _session;

  Future<Result<List<FoodItem>>> call(Uint8List jpeg) async {
    await _tipsCache.ensureLoaded();
    final result = await _ai.analyzeMealPhoto(
      jpeg,
      goal: _session.goal,
      allowedTips: allowedTipsForAi(_tipsCache, _session.goal),
    );
    return switch (result) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => toItems(value, _tipResolver),
    };
  }

  /// Dùng chung cho quét ảnh và nhập tên món:
  /// không nhận ra món -> lỗi notRecognized (UI chuyển sang nhập thủ công);
  /// ngược lại gắn gợi ý (lọc mã lạ + bổ sung theo quy tắc).
  static Result<List<FoodItem>> toItems(ParsedMealResponse parsed, TipResolver tips) {
    if (parsed.hasNoFood) {
      return const Err(AppFailure(FailureType.notRecognized, ScanStrings.notRecognized));
    }
    return Ok([
      for (final p in parsed.items) p.item.copyWith(tips: tips.forAiCodes(p.tipCodes, p.item)),
    ]);
  }
}
