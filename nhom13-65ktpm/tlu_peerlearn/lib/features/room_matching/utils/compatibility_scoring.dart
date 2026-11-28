class CompatibilityScoring {
  static const timeWeight = 0.50;
  static const academicWeight = 0.30;
  static const capacityWeight = 0.20;

  static double bounded(double value) =>
      !value.isFinite ? 0 : value.clamp(0.0, 1.0).toDouble();

  static double calculate({
    required double timeScore,
    required double academicScore,
    required double capacityScore,
  }) => bounded(
    timeWeight * bounded(timeScore) +
        academicWeight * bounded(academicScore) +
        capacityWeight * bounded(capacityScore),
  );

  static double timeFit(Iterable<int> firstSlots, Iterable<int> secondSlots) {
    final first = firstSlots.where((slot) => slot >= 0 && slot < 21).toSet();
    final second = secondSlots.where((slot) => slot >= 0 && slot < 21).toSet();
    final union = first.union(second).length;
    if (union == 0) return 0;
    return bounded(first.intersection(second).length / union);
  }

  static double academicFit({
    double? mentorGrade,
    String? mentorStrength,
    String? menteeNeed,
  }) {
    if (mentorGrade != null && mentorGrade.isFinite) {
      return bounded(mentorGrade / 10);
    }

    final strengths = _tokens(mentorStrength);
    final needs = _tokens(menteeNeed);
    if (strengths.isEmpty || needs.isEmpty) return 0.5;

    final union = strengths.union(needs).length;
    if (union == 0) return 0.5;
    return bounded(strengths.intersection(needs).length / union);
  }

  static double capacityFit({
    required int maxMentees,
    required int currentMentees,
  }) {
    if (maxMentees <= 0) return 0;
    if (currentMentees < 0) return 1;
    return bounded((maxMentees - currentMentees) / maxMentees);
  }

  static Set<String> _tokens(String? text) {
    final normalized = text?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return {};
    return normalized
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((word) => word.length > 1)
        .toSet();
  }
}
