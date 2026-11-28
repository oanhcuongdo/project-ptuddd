import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../core/result.dart';
import '../../core/strings/scan_strings.dart';
import '../../domain/entities/tip.dart';
import '../../domain/enums.dart';
import 'gemini_client.dart';
import 'parsers/meal_response_parser.dart';
import 'prompt_builder.dart';
import 'schemas.dart';

/// Phân tích món ăn bằng Gemini: ảnh (quét món) hoặc văn bản (nhập tên món).
///
/// Ảnh chỉ được gửi tới Gemini để phân tích rồi bỏ, KHÔNG lưu lên Cloud.
class AiAnalysisService {
  AiAnalysisService(this._client);

  final GeminiClient _client;

  /// [jpeg]: ảnh đã nén (cạnh dài ~1024px, JPEG ~80%).
  /// [allowedTips]: gợi ý được phép chọn (lọc theo mục tiêu) -> enum trong schema.
  Future<Result<ParsedMealResponse>> analyzeMealPhoto(
    Uint8List jpeg, {
    required Goal goal,
    required List<Tip> allowedTips,
  }) {
    return _run(
      goal: goal,
      allowedTips: allowedTips,
      parts: [
        TextPart(PromptBuilder.mealPhotoPrompt()),
        InlineDataPart('image/jpeg', jpeg),
      ],
    );
  }

  /// Người dùng gõ tên món -> gọi Gemini chỉ với văn bản, cùng schema (1 món).
  Future<Result<ParsedMealResponse>> analyzeFoodText(
    String dishName, {
    required Goal goal,
    required List<Tip> allowedTips,
  }) {
    return _run(
      goal: goal,
      allowedTips: allowedTips,
      parts: [TextPart(PromptBuilder.foodTextPrompt(dishName))],
    );
  }

  Future<Result<ParsedMealResponse>> _run({
    required Goal goal,
    required List<Tip> allowedTips,
    required List<Part> parts,
  }) async {
    final raw = await _client.generateJson(
      systemInstruction: PromptBuilder.systemInstruction(goal: goal, allowedTips: allowedTips),
      schema: AiSchemas.mealAnalysis(allowedTips.map((t) => t.code).toList()),
      parts: parts,
    );
    switch (raw) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        try {
          return Ok(MealResponseParser.parse(value));
        } on FormatException catch (e) {
          debugPrint('AI JSON parse failed: $e');
          return Err(AppFailure(FailureType.invalidResponse, ScanStrings.invalidResponse, e));
        }
    }
  }
}
