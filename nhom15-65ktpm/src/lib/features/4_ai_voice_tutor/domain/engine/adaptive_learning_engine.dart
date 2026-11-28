import 'dart:math';
import 'package:equatable/equatable.dart';
import '../../../../shared/entities/attempt_log.dart';

/// Chế độ luyện tập toán học
enum PracticeMode {
  fingerMath,
  flashAnzan,
}

/// Hành động thích ứng theo đặc tả 7.8
enum AdaptationAction {
  levelUp,
  levelDown,
  maintain,
}

/// Hành động thích ứng tương thích ngược với AdaptiveTutorEngine cũ
enum AdaptiveAction {
  speedUp,
  slowDown,
  guideHighlight,
  stayCurrent,
}

/// Bản ghi kết quả 1 lượt làm bài theo đặc tả 7.8
class AttemptResult extends Equatable {
  final bool isCorrect;
  final int responseTimeMs;
  final PracticeMode mode;
  final DateTime timestamp;
  final int difficultyLevel;
  final int flashDurationMs;

  AttemptResult({
    required this.isCorrect,
    required this.responseTimeMs,
    this.mode = PracticeMode.fingerMath,
    DateTime? timestamp,
    this.difficultyLevel = 1,
    this.flashDurationMs = 1200,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Chuyển đổi từ AttemptLog
  factory AttemptResult.fromAttemptLog(AttemptLog log, {PracticeMode? mode}) {
    final inferredMode = mode ??
        (log.answeredVia == 'voice' || log.questionText.contains('Flash')
            ? PracticeMode.flashAnzan
            : PracticeMode.fingerMath);

    return AttemptResult(
      isCorrect: log.isCorrect,
      responseTimeMs: log.responseTimeMs,
      mode: inferredMode,
      timestamp: DateTime.tryParse(log.timestamp) ?? DateTime.now(),
      difficultyLevel: log.difficultyLevel,
      flashDurationMs: log.flashAnzanSpeedMs,
    );
  }

  /// Chuyển đổi sang AttemptLog
  AttemptLog toAttemptLog({String questionId = ''}) {
    return AttemptLog(
      questionId: questionId,
      userAnswer: 0,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      answeredVia: mode == PracticeMode.flashAnzan ? 'voice' : 'abacus_touch',
      timestamp: timestamp.toIso8601String(),
      difficultyLevel: difficultyLevel,
      flashAnzanSpeedMs: flashDurationMs,
    );
  }

  @override
  List<Object?> get props => [
        isCorrect,
        responseTimeMs,
        mode,
        timestamp,
        difficultyLevel,
        flashDurationMs,
      ];
}

/// Bí danh AttemptRecord
typedef AttemptRecord = AttemptResult;

/// Trạng thái học tập thích ứng của trẻ
class AdaptiveState extends Equatable {
  final int currentDifficulty;
  final int flashDurationMs;
  final bool isFingerGuideEnabled;
  final String adaptationFeedbackMessage;
  final String reason;
  final AdaptationAction lastAction;
  final List<AttemptResult> slidingWindow;
  final int totalAttemptsProcessed;

  const AdaptiveState({
    this.currentDifficulty = 1,
    this.flashDurationMs = 1200,
    this.isFingerGuideEnabled = false,
    this.adaptationFeedbackMessage = '',
    this.reason = '',
    this.lastAction = AdaptationAction.maintain,
    this.slidingWindow = const [],
    this.totalAttemptsProcessed = 0,
  });

  AdaptiveState copyWith({
    int? currentDifficulty,
    int? flashDurationMs,
    bool? isFingerGuideEnabled,
    String? adaptationFeedbackMessage,
    String? reason,
    AdaptationAction? lastAction,
    List<AttemptResult>? slidingWindow,
    int? totalAttemptsProcessed,
  }) {
    return AdaptiveState(
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      flashDurationMs: flashDurationMs ?? this.flashDurationMs,
      isFingerGuideEnabled: isFingerGuideEnabled ?? this.isFingerGuideEnabled,
      adaptationFeedbackMessage:
          adaptationFeedbackMessage ?? this.adaptationFeedbackMessage,
      reason: reason ?? this.reason,
      lastAction: lastAction ?? this.lastAction,
      slidingWindow: slidingWindow ?? this.slidingWindow,
      totalAttemptsProcessed:
          totalAttemptsProcessed ?? this.totalAttemptsProcessed,
    );
  }

  double get currentAccuracy {
    if (slidingWindow.isEmpty) return 0.0;
    final correct = slidingWindow.where((a) => a.isCorrect).length;
    return correct / slidingWindow.length;
  }

  int get avgResponseTimeMs {
    if (slidingWindow.isEmpty) return 0;
    final total = slidingWindow
        .map((a) => a.responseTimeMs)
        .reduce((a, b) => a + b);
    return total ~/ slidingWindow.length;
  }

  @override
  List<Object?> get props => [
        currentDifficulty,
        flashDurationMs,
        isFingerGuideEnabled,
        adaptationFeedbackMessage,
        reason,
        lastAction,
        slidingWindow,
        totalAttemptsProcessed,
      ];
}

/// Kết quả quyết định thích ứng trả về cho giao diện
class AdaptiveDecision extends Equatable {
  final AdaptiveAction action;
  final AdaptationAction adaptationAction;
  final int recommendedSpeedMs;
  final int recommendedLevel;
  final bool fingerGuideEnabled;
  final String reason;
  final String message;
  final double accuracy;
  final int avgResponseTimeMs;

  const AdaptiveDecision({
    required this.action,
    this.adaptationAction = AdaptationAction.maintain,
    required this.recommendedSpeedMs,
    this.recommendedLevel = 1,
    this.fingerGuideEnabled = false,
    this.reason = '',
    required this.message,
    this.accuracy = 0.0,
    this.avgResponseTimeMs = 0,
  });

  /// Cờ hiển thị gợi ý ngón tay theo yêu cầu đồ án
  bool get showFingerHint => fingerGuideEnabled;

  bool get isLevelUp =>
      adaptationAction == AdaptationAction.levelUp ||
      action == AdaptiveAction.speedUp;

  bool get isLevelDown =>
      adaptationAction == AdaptationAction.levelDown ||
      action == AdaptiveAction.guideHighlight ||
      action == AdaptiveAction.slowDown;

  bool get isMaintain =>
      adaptationAction == AdaptationAction.maintain ||
      action == AdaptiveAction.stayCurrent;

  @override
  List<Object?> get props => [
        action,
        adaptationAction,
        recommendedSpeedMs,
        recommendedLevel,
        fingerGuideEnabled,
        reason,
        message,
        accuracy,
        avgResponseTimeMs,
      ];
}

/// Động cơ gia sư thích ứng thông minh (Adaptive Learning Engine - Mục 7.8)
/// - Cửa sổ trượt 5 bài gần nhất (Sliding Window N = 5).
/// - Cơ chế chống dao động (Hysteresis / Cooldown): Sau khi điều chỉnh cấp độ,
///   cửa sổ trượt được reset để trẻ tích lũy đủ 5 bài ở cấp độ mới trước khi đánh giá tiếp.
/// - Quy tắc thăng cấp: accuracy >= 80% & avgResponseTimeMs < 2500ms
///   -> Tăng độ khó (Finger Math) / Giảm thời gian chớp số (-200ms, sàn 300ms) (Flash Anzan)
/// - Quy tắc hạ cấp & hỗ trợ: accuracy < 50% hoặc avgResponseTimeMs > 6000ms
///   -> Giảm độ khó (sàn 1) / Tăng thời gian chớp (+200ms) & Bật hướng dẫn thị phạm ngón tay (fingerGuideEnabled = true)
/// - Giữ nguyên: Trường hợp còn lại.
class AdaptiveLearningEngine {
  static const int defaultWindowSize = 5;
  static const int minSpeedMs = 300;
  static const int maxSpeedMs = 2500;
  static const int minLevel = 1;
  static const int maxLevel = 4;
  static const int speedStepMs = 200;
  static const int fastResponseThresholdMs = 2500;
  static const int slowResponseThresholdMs = 6000;
  static const double highAccuracyThreshold = 0.8;
  static const double lowAccuracyThreshold = 0.5;

  final int windowSize;
  final bool resetWindowOnAdaptation;
  AdaptiveState _state;

  AdaptiveLearningEngine({
    this.windowSize = defaultWindowSize,
    this.resetWindowOnAdaptation = true,
    AdaptiveState? initialState,
  }) : _state = initialState ?? const AdaptiveState();

  AdaptiveState get state => _state;
  List<AttemptResult> get window => List.unmodifiable(_state.slidingWindow);

  /// Xử lý 1 lượt làm bài và thực hiện thích ứng khi đủ cửa sổ trượt
  AdaptiveDecision processAttempt(AttemptResult attempt) {
    // 1. Thêm bản ghi mới vào cửa sổ trượt
    final updatedWindow = List<AttemptResult>.from(_state.slidingWindow)
      ..add(attempt);

    // Giữ kích thước tối đa windowSize (cửa sổ trượt)
    if (updatedWindow.length > windowSize) {
      updatedWindow.removeAt(0);
    }

    final totalProcessed = _state.totalAttemptsProcessed + 1;

    // 2. Nếu chưa tích lũy đủ 5 bài, duy trì thông số hiện tại
    if (updatedWindow.length < windowSize) {
      _state = _state.copyWith(
        slidingWindow: updatedWindow,
        totalAttemptsProcessed: totalProcessed,
        lastAction: AdaptationAction.maintain,
        adaptationFeedbackMessage: '',
      );

      return AdaptiveDecision(
        action: AdaptiveAction.stayCurrent,
        adaptationAction: AdaptationAction.maintain,
        recommendedSpeedMs: _state.flashDurationMs,
        recommendedLevel: _state.currentDifficulty,
        fingerGuideEnabled: _state.isFingerGuideEnabled,
        reason:
            'Đang tích lũy dữ liệu cửa sổ trượt (${updatedWindow.length}/$windowSize bài).',
        message: 'Bé hãy tiếp tục làm bài nhé!',
        accuracy: _state.currentAccuracy,
        avgResponseTimeMs: _state.avgResponseTimeMs,
      );
    }

    // 3. Đã đủ 5 bài -> Tính toán độ chính xác và thời gian phản hồi trung bình
    final correctCount = updatedWindow.where((a) => a.isCorrect).length;
    final accuracy = correctCount / updatedWindow.length;
    final totalTime = updatedWindow
        .map((a) => a.responseTimeMs)
        .reduce((a, b) => a + b);
    final avgTime = totalTime ~/ updatedWindow.length;

    // QUY TẮC 1: Thăng cấp (Level Up / Speed Up)
    // accuracy >= 80% (tức đúng >= 4/5 câu) VÀ avgResponseTimeMs < 2500
    if (accuracy >= highAccuracyThreshold && avgTime < fastResponseThresholdMs) {
      final newLevel = min(_state.currentDifficulty + 1, maxLevel);
      final newSpeed =
          max(_state.flashDurationMs - speedStepMs, minSpeedMs);
      final reachedMax = attempt.mode == PracticeMode.fingerMath
          ? _state.currentDifficulty >= maxLevel
          : _state.flashDurationMs <= minSpeedMs;

      final message = reachedMax
          ? (attempt.mode == PracticeMode.fingerMath
              ? 'Bé đã đạt cấp độ tối đa siêu xuất sắc! Tiếp tục giữ vững phong độ nhé! 🏆'
              : 'Bé đã đạt tốc độ chớp số thần tốc tối đa ($minSpeedMs ms)! Quá siêu! ⚡')
          : (attempt.mode == PracticeMode.fingerMath
              ? 'Bé tính siêu đẳng! Tự động nâng lên Cấp độ $newLevel! 🌟'
              : 'Bé tính siêu nhanh! Tự động tăng tốc độ chớp số lên ${newSpeed}ms! 🚀');

      final reason =
          'Tỷ lệ đúng ${(accuracy * 100).toInt()}% >= 80% và thời gian phản hồi ${avgTime}ms < 2500ms. Thăng cấp thử thách mới.';

      final decision = AdaptiveDecision(
        action: AdaptiveAction.speedUp,
        adaptationAction: AdaptationAction.levelUp,
        recommendedSpeedMs: newSpeed,
        recommendedLevel: newLevel,
        fingerGuideEnabled: false, // Tắt hướng dẫn khi thăng cấp
        reason: reason,
        message: message,
        accuracy: accuracy,
        avgResponseTimeMs: avgTime,
      );

      // Cập nhật trạng thái và áp dụng cơ chế chống dao động
      _state = _state.copyWith(
        currentDifficulty: newLevel,
        flashDurationMs: newSpeed,
        isFingerGuideEnabled: false,
        adaptationFeedbackMessage: message,
        reason: reason,
        lastAction: AdaptationAction.levelUp,
        slidingWindow: resetWindowOnAdaptation ? const [] : updatedWindow,
        totalAttemptsProcessed: totalProcessed,
      );

      return decision;
    }

    // QUY TẮC 2: Hạ cấp & Hỗ trợ thị phạm (Level Down & Assist)
    // accuracy < 50% (tức đúng <= 2/5 câu) HOẶC avgResponseTimeMs > 6000
    if (accuracy < lowAccuracyThreshold || avgTime > slowResponseThresholdMs) {
      final newLevel = max(_state.currentDifficulty - 1, minLevel);
      final newSpeed =
          min(_state.flashDurationMs + speedStepMs, maxSpeedMs);

      final message = attempt.mode == PracticeMode.fingerMath
          ? 'Không sao đâu! Thầy bật hướng dẫn thị phạm ngón tay và điều chỉnh bài phù hợp giúp bé nhé! 💡'
          : 'Thầy giảm tốc độ chớp số (${newSpeed}ms) để bé nhìn rõ hơn nhé! Cố lên nào! 💡';

      final reason =
          'Tỷ lệ đúng ${(accuracy * 100).toInt()}% < 50% hoặc thời gian phản hồi ${avgTime}ms > 6000ms. Hạ cấp độ và kích hoạt hướng dẫn trực quan.';

      final decision = AdaptiveDecision(
        action: AdaptiveAction.guideHighlight,
        adaptationAction: AdaptationAction.levelDown,
        recommendedSpeedMs: newSpeed,
        recommendedLevel: newLevel,
        fingerGuideEnabled: true, // Kích hoạt hướng dẫn thị phạm
        reason: reason,
        message: message,
        accuracy: accuracy,
        avgResponseTimeMs: avgTime,
      );

      // Cập nhật trạng thái và áp dụng cơ chế chống dao động
      _state = _state.copyWith(
        currentDifficulty: newLevel,
        flashDurationMs: newSpeed,
        isFingerGuideEnabled: true,
        adaptationFeedbackMessage: message,
        reason: reason,
        lastAction: AdaptationAction.levelDown,
        slidingWindow: resetWindowOnAdaptation ? const [] : updatedWindow,
        totalAttemptsProcessed: totalProcessed,
      );

      return decision;
    }

    // QUY TẮC 3: Giữ nguyên (Maintain)
    final message =
        'Bé làm rất đều tay (${(accuracy * 100).toInt()}% đúng, ${avgTime}ms), cùng tiếp tục nào! ⭐';
    final reason =
        'Kết quả ổn định trong phạm vi an toàn (${(accuracy * 100).toInt()}% đúng, ${avgTime}ms). Duy trì nhịp độ hiện tại.';

    final decision = AdaptiveDecision(
      action: AdaptiveAction.stayCurrent,
      adaptationAction: AdaptationAction.maintain,
      recommendedSpeedMs: _state.flashDurationMs,
      recommendedLevel: _state.currentDifficulty,
      fingerGuideEnabled: _state.isFingerGuideEnabled,
      reason: reason,
      message: message,
      accuracy: accuracy,
      avgResponseTimeMs: avgTime,
    );

    _state = _state.copyWith(
      slidingWindow: updatedWindow,
      totalAttemptsProcessed: totalProcessed,
      lastAction: AdaptationAction.maintain,
      adaptationFeedbackMessage: message,
      reason: reason,
    );

    return decision;
  }

  /// Reset toàn bộ phiên và cửa sổ trượt
  void reset() {
    _state = const AdaptiveState();
  }

  /// Cập nhật thủ công cấu hình từ cài đặt
  void updateConfig({
    int? difficulty,
    int? flashDurationMs,
    bool? isFingerGuideEnabled,
  }) {
    _state = _state.copyWith(
      currentDifficulty: difficulty,
      flashDurationMs: flashDurationMs,
      isFingerGuideEnabled: isFingerGuideEnabled,
    );
  }

  /// Hàm tiện ích tĩnh tương thích ngược với AdaptiveTutorEngine cũ
  static AdaptiveDecision evaluatePerformance({
    required List<AttemptLog> recentAttempts,
    int currentFlashSpeedMs = 1200,
    int currentLevel = 1,
    PracticeMode? mode,
  }) {
    if (recentAttempts.length < defaultWindowSize) {
      final acc = recentAttempts.isEmpty
          ? 0.0
          : recentAttempts.where((a) => a.isCorrect).length /
              recentAttempts.length;
      final avgTime = recentAttempts.isEmpty
          ? 0
          : (recentAttempts.map((a) => a.responseTimeMs).reduce((a, b) => a + b) ~/
              recentAttempts.length);

      return AdaptiveDecision(
        action: AdaptiveAction.stayCurrent,
        adaptationAction: AdaptationAction.maintain,
        recommendedSpeedMs: currentFlashSpeedMs,
        recommendedLevel: currentLevel,
        fingerGuideEnabled: false,
        reason:
            'Chưa đủ $defaultWindowSize bài gần nhất để đánh giá thích ứng (${recentAttempts.length}/$defaultWindowSize bài).',
        message: 'Bé hãy tiếp tục làm bài nhé!',
        accuracy: acc,
        avgResponseTimeMs: avgTime,
      );
    }

    // Lấy đúng 5 câu hỏi gần nhất từ danh sách
    final window = recentAttempts.take(defaultWindowSize).toList();
    final correctCount = window.where((a) => a.isCorrect).length;
    final accuracy = correctCount / defaultWindowSize;

    final totalTime =
        window.map((a) => a.responseTimeMs).reduce((a, b) => a + b);
    final avgTime = totalTime / defaultWindowSize;

    // 1. Tăng tốc độ & Tăng độ khó: accuracy >= 80% & thời gian < 2500ms
    if (accuracy >= 0.8 && avgTime < 2500) {
      final newSpeed =
          (currentFlashSpeedMs - 200).clamp(500, maxSpeedMs);
      final newLevel = min(currentLevel + 1, 3);
      return AdaptiveDecision(
        action: AdaptiveAction.speedUp,
        adaptationAction: AdaptationAction.levelUp,
        recommendedSpeedMs: newSpeed,
        recommendedLevel: newLevel,
        fingerGuideEnabled: false,
        reason:
            'Tỷ lệ đúng ${(accuracy * 100).toInt()}% >= 80% và thời gian phản hồi trung bình ${avgTime.toInt()}ms < 2500ms. Đề xuất tăng độ khó và tăng tốc độ chớp số.',
        message: 'Bé tính siêu đẳng! Thầy nâng độ khó lên nhé! 🚀',
        accuracy: accuracy,
        avgResponseTimeMs: avgTime.toInt(),
      );
    }

    // 2. Giảm độ khó & Bật thị phạm ngón tay: accuracy < 50% hoặc thời gian > 6000ms
    if (accuracy < 0.5 || avgTime > 6000) {
      final newSpeed =
          (currentFlashSpeedMs + 200).clamp(500, maxSpeedMs);
      final newLevel = max(currentLevel - 1, 1);
      return AdaptiveDecision(
        action: AdaptiveAction.guideHighlight,
        adaptationAction: AdaptationAction.levelDown,
        recommendedSpeedMs: newSpeed,
        recommendedLevel: newLevel,
        fingerGuideEnabled: true,
        reason:
            'Tỷ lệ đúng ${(accuracy * 100).toInt()}% < 50% hoặc thời gian phản hồi ${avgTime.toInt()}ms > 6000ms. Đề xuất giảm cấp độ khó và bật hướng dẫn ngón tay.',
        message: 'Không sao đâu! Thầy mở hướng dẫn từng bước giúp bé nhé! 💡',
        accuracy: accuracy,
        avgResponseTimeMs: avgTime.toInt(),
      );
    }

    // 3. Duy trì độ khó và tốc độ hiện tại
    return AdaptiveDecision(
      action: AdaptiveAction.stayCurrent,
      adaptationAction: AdaptationAction.maintain,
      recommendedSpeedMs: currentFlashSpeedMs,
      recommendedLevel: currentLevel,
      fingerGuideEnabled: false,
      reason:
          'Bé đạt kết quả ổn định (${(accuracy * 100).toInt()}% đúng, ${avgTime.toInt()}ms). Giữ nguyên độ khó và tắt gợi ý bắt buộc.',
      message: 'Bé làm rất đều tay, cùng tiếp tục nào! ⭐',
      accuracy: accuracy,
      avgResponseTimeMs: avgTime.toInt(),
    );
  }
}

/// Bí danh AdaptiveTutorEngine để tương thích ngược 100% với mã nguồn cũ
typedef AdaptiveTutorEngine = AdaptiveLearningEngine;
