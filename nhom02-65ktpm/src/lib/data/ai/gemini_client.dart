import 'dart:async';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_config.dart';
import '../../core/result.dart';
import '../../core/strings/scan_strings.dart';
import 'rate_limiter.dart';

/// Gọi Gemini qua Firebase AI Logic (provider: Gemini Developer API, gói Spark).
///
/// Nhiệm vụ: giới hạn tần suất, đặt timeout, yêu cầu trả JSON theo schema,
/// và đổi mọi lỗi thành [AppFailure] thân thiện. KHÔNG bao giờ ném lỗi lên UI.
/// Không log nội dung ảnh.
class GeminiClient {
  GeminiClient(this._ai, this._rateLimiter);

  final FirebaseAI _ai;
  final RateLimiter _rateLimiter;

  /// Trả về chuỗi JSON thô của model (chưa parse).
  Future<Result<String>> generateJson({
    required String systemInstruction,
    required Schema schema,
    required List<Part> parts,
  }) async {
    if (!_rateLimiter.tryAcquire()) {
      return const Err(AppFailure(FailureType.rateLimited, ScanStrings.rateLimited));
    }
    try {
      final model = _ai.generativeModel(
        model: AppConfig.geminiModel,
        systemInstruction: Content.system(systemInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
        ),
      );
      final response =
          await model.generateContent([Content.multi(parts)]).timeout(AppConfig.aiTimeout);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return const Err(AppFailure(FailureType.invalidResponse, ScanStrings.invalidResponse));
      }
      return Ok(text);
    } on TimeoutException catch (e) {
      return Err(AppFailure(FailureType.timeout, ScanStrings.timeout, e));
    } on QuotaExceeded catch (e) {
      _log(e);
      return Err(AppFailure(FailureType.quotaExceeded, ScanStrings.quota, e));
    } on SocketException catch (e) {
      return Err(AppFailure(FailureType.network, ScanStrings.network, e));
    } catch (e) {
      _log(e);
      return Err(mapError(e));
    }
  }

  /// Phân loại lỗi dựa trên nội dung thông báo (SDK gói lỗi HTTP thành chuỗi).
  @visibleForTesting
  static AppFailure mapError(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('app check') ||
        text.contains('appcheck') ||
        text.contains('403') ||
        text.contains('permission_denied') ||
        text.contains('permission denied')) {
      return AppFailure(FailureType.appCheck, ScanStrings.appCheck, e);
    }
    if (text.contains('429') || text.contains('resource_exhausted') || text.contains('quota')) {
      return AppFailure(FailureType.quotaExceeded, ScanStrings.quota, e);
    }
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection')) {
      return AppFailure(FailureType.network, ScanStrings.network, e);
    }
    return AppFailure(FailureType.unknown, ScanStrings.unknown, e);
  }

  static void _log(Object e) {
    if (kDebugMode) debugPrint('Gemini error: $e');
  }
}
