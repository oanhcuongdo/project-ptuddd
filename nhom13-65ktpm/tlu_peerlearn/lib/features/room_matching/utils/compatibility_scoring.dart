class CompatibilityScoring {
  static const timeWeight = 0.50;
  static const academicWeight = 0.30;
  static const capacityWeight = 0.20;

  static double _bounded(double value) =>
      value.isNaN ? 0 : value.clamp(0.0, 1.0).toDouble();

  static double calculate({
    required double timeScore,
    required double academicScore,
    required double capacityScore,
  }) =>
      _bounded(
        timeWeight * _bounded(timeScore) +
            academicWeight * _bounded(academicScore) +
            capacityWeight * _bounded(capacityScore),
      );

  static double timeFit(Iterable<int> firstSlots, Iterable<int> secondSlots) {
    final first = firstSlots.toSet();
    final second = secondSlots.toSet();
    final union = first.union(second).length;
    if (union == 0) return 0;
    return first.intersection(second).length / union;
  }

  static double academicFit(double? mentorGrade) =>
      mentorGrade == null ? 0.5 : _bounded(mentorGrade / 10);

  static double capacityFit({
    required int maxMentees,
    required int currentMentees,
  }) {
    if (maxMentees <= 0) return 0;
    return _bounded((maxMentees - currentMentees) / maxMentees);
  }
}
