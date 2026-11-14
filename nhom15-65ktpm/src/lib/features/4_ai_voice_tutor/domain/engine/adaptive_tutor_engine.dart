import '../../../../shared/entities/attempt_log.dart';

enum AdaptiveAction { speedUp, slowDown, guideHighlight, stayCurrent }

class AdaptiveDecision {
  final AdaptiveAction action;
  final int recommendedSpeedMs;
  final String message;

  const AdaptiveDecision({
    required this.action,
    required this.recommendedSpeedMs,
    required this.message,
  });
}

class AdaptiveTutorEngine {
  /// Phân tích dữ liệu học tập của bé để tự động thích ứng độ khó và tốc độ
  static AdaptiveDecision evaluatePerformance({
    required List<AttemptLog> recentAttempts,
    int currentFlashSpeedMs = 1200,
  }) {
    if (recentAttempts.isEmpty) {
      return AdaptiveDecision(
        action: AdaptiveAction.stayCurrent,
        recommendedSpeedMs: currentFlashSpeedMs,
        message: 'Bé hãy sẵn sàng bắt đầu bài học nào!',
      );
    }

    // Lấy tối đa 5 câu hỏi gần nhất
    final window = recentAttempts.take(5).toList();
    final correctCount = window.where((a) => a.isCorrect).length;
    final accuracy = correctCount / window.length;

    final avgTime =
        window.map((a) => a.responseTimeMs).reduce((a, b) => a + b) /
            window.length;

    // Bé tính rất nhanh và chính xác cao (>= 80% & thời gian < 2.5s)
    if (accuracy >= 0.8 && avgTime <= 2500) {
      final newSpeed = (currentFlashSpeedMs - 200).clamp(500, 2000);
      return AdaptiveDecision(
        action: AdaptiveAction.speedUp,
        recommendedSpeedMs: newSpeed,
        message: 'Bé tính siêu đẳng! Thầy tăng tốc độ chớp số lên nhé! 🚀',
      );
    }

    // Bé gặp khó khăn hoặc trả lời chậm (accuracy < 60% hoặc thời gian > 6.0s)
    if (accuracy < 0.6 || avgTime >= 6000) {
      final newSpeed = (currentFlashSpeedMs + 200).clamp(500, 2500);
      return AdaptiveDecision(
        action: AdaptiveAction.guideHighlight,
        recommendedSpeedMs: newSpeed,
        message: 'Không sao đâu! Thầy mở hướng dẫn từng bước giúp bé nhé! 💡',
      );
    }

    // Bé duy trì tốc độ và độ chính xác ổn định
    return AdaptiveDecision(
      action: AdaptiveAction.stayCurrent,
      recommendedSpeedMs: currentFlashSpeedMs,
      message: 'Bé làm rất đều tay, cùng tiếp tục nào! ⭐',
    );
  }
}
