/// Learner rating (F9): the mean score of the latest attempts, bucketed into
/// levels that F10 uses to group learners.
library;

/// Attempts averaged into the rate.
const rateWindow = 20;

/// Fewer attempts than this give no rate: a handful of scores swings too much.
const minAttemptsForRate = 10;

enum Level {
  beginner('Beginner', 0),
  elementary('Elementary', 50),
  intermediate('Intermediate', 70),
  advanced('Advanced', 85);

  final String label;
  final int minRate;
  const Level(this.label, this.minRate);

  static Level of(double rate) =>
      Level.values.lastWhere((l) => rate >= l.minRate);
}

class Rate {
  final double value;
  final Level level;
  final int attempts;
  const Rate(this.value, this.level, this.attempts);
}

/// [newestFirst] = attempt scores, newest first; only the first [rateWindow]
/// count. Returns null until the learner has [minAttemptsForRate] attempts.
Rate? computeRate(List<int> newestFirst) {
  final recent = newestFirst.take(rateWindow).toList();
  if (recent.length < minAttemptsForRate) return null;
  final value = recent.reduce((a, b) => a + b) / recent.length;
  return Rate(value, Level.of(value), recent.length);
}
