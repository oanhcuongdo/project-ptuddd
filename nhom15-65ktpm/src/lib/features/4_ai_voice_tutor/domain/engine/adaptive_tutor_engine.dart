import 'dart:math';
import '../../../../shared/entities/attempt_log.dart';

enum AdaptiveAction {
  speedUp,
  slowDown,
  guideHighlight,
  stayCurrent,
}

class AdaptiveDecision {
  final AdaptiveAction action;
  final int recommendedSpeedMs;
  final int recommendedLevel;
  final bool fingerGuideEnabled;
  final String reason;
  final String message;

  const AdaptiveDecision({
    required this.action,
    required this.recommendedSpeedMs,
    this.recommendedLevel = 1,
    this.fingerGuideEnabled = false,
    this.reason = '',
    required this.message,
  });
}

/// Động cơ gia sư thích ứng thông minh (Adaptive Learning Engine):
/// Phân tích lịch sử làm bài theo CỬA SỔ TRƯỢT 5 bài gần nhất (Sliding Window size = 5).
/// - Tăng độ khó / tăng tốc: accuracy >= 0.8 & avgResponseTimeMs <= 2500 -> speedUp, giảm thời gian chớp số (-200ms, sàn 300ms)
/// - Giảm độ khó / bật hỗ trợ ngón tay: accuracy < 0.6 hoặc avgResponseTimeMs >= 6000 -> guideHighlight, tăng thời gian (+200ms, trần 2500ms) & bật thị phạm fingerGuideEnabled
/// - Duy trì: stayCurrent
class AdaptiveTutorEngine {
  static const int windowSize = 5;
  static const int minSpeedMs = 300;
  static const int maxSpeedMs = 2500;
  static const int minLevel = 1;
  static const int maxLevel = 4;

  /// Phân tích dữ liệu học tập của bé để tự động thích ứng độ khó và tốc độ
  static AdaptiveDecision evaluatePerformance({
    required List<AttemptLog> recentAttempts,
    int currentFlashSpeedMs = 1200,
    int currentLevel = 1,
  }) {
    if (recentAttempts.isEmpty) {
      return AdaptiveDecision(
        action: AdaptiveAction.stayCurrent,
        recommendedSpeedMs: currentFlashSpeedMs,
        recommendedLevel: currentLevel,
        fingerGuideEnabled: false,
        reason: 'Chưa có đủ lịch sử bài làm.',
        message: 'Bé hãy sẵn sàng bắt đầu bài học nào!',
      );
    }

    // Lấy cửa sổ trượt tối đa 5 câu hỏi gần nhất
    final window = recentAttempts.take(windowSize).toList();
    final correctCount = window.where((a) => a.isCorrect).length;
    final accuracy = correctCount / window.length;

    final avgTime =
        window.map((a) => a.responseTimeMs).reduce((a, b) => a + b) /
            window.length;

    // 1. Tăng tốc độ & Tăng độ khó: accuracy >= 80% & thời gian <= 2.5s
    if (accuracy >= 0.8 && avgTime <= 2500) {
      final newSpeed = (currentFlashSpeedMs - 200).clamp(minSpeedMs, 2000);
      final newLevel = min(currentLevel + 1, maxLevel);
      return AdaptiveDecision(
        action: AdaptiveAction.speedUp,
        recommendedSpeedMs: newSpeed,
        recommendedLevel: newLevel,
        fingerGuideEnabled: false,
        reason:
            'Tỷ lệ đúng ${(accuracy * 100).toInt()}% >= 80% và thời gian phản hồi trung bình ${avgTime.toInt()}ms <= 2500ms. Tự động tăng tốc độ chớp số và nâng cấp bài toán.',
        message: 'Bé tính siêu đẳng! Thầy tăng tốc độ chớp số lên nhé! 🚀',
      );
    }

    // 2. Giảm độ khó & Bật thị phạm ngón tay: accuracy < 60% hoặc thời gian >= 6.0s
    if (accuracy < 0.6 || avgTime >= 6000) {
      final newSpeed = (currentFlashSpeedMs + 200).clamp(500, maxSpeedMs);
      final newLevel = max(currentLevel - 1, minLevel);
      return AdaptiveDecision(
        action: AdaptiveAction.guideHighlight,
        recommendedSpeedMs: newSpeed,
        recommendedLevel: newLevel,
        fingerGuideEnabled: true,
        reason:
            'Tỷ lệ đúng ${(accuracy * 100).toInt()}% < 60% hoặc thời gian phản hồi ${avgTime.toInt()}ms >= 6000ms. Tự động kích hoạt mô hình hướng dẫn gập mở ngón tay Finger Math.',
        message: 'Không sao đâu! Thầy mở hướng dẫn từng bước giúp bé nhé! 💡',
      );
    }

    // 3. Duy trì độ khó và tốc độ hiện tại
    return AdaptiveDecision(
      action: AdaptiveAction.stayCurrent,
      recommendedSpeedMs: currentFlashSpeedMs,
      recommendedLevel: currentLevel,
      fingerGuideEnabled: false,
      reason:
          'Bé đạt kết quả ổn định (${(accuracy * 100).toInt()}% đúng, ${avgTime.toInt()}ms). Giữ nguyên nhịp độ hiện tại để củng cố kỹ năng.',
      message: 'Bé làm rất đều tay, cùng tiếp tục nào! ⭐',
    );
  }
}

/// Bí danh AdaptiveLearningEngine để đáp ứng đầy đủ tên gọi theo đặc tả 7.8
typedef AdaptiveLearningEngine = AdaptiveTutorEngine;
