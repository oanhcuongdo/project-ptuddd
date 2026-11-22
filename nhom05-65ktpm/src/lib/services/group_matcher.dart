import '../scoring/rate.dart';

/// A candidate for F10 rate-based study-group matching.
class LearnerCandidate {
  final String uid;
  final String displayName;
  final Rate? rate;

  const LearnerCandidate({
    required this.uid,
    required this.displayName,
    required this.rate,
  });
}

/// Suggested group. A mentor is assigned from the supplied mentor roster.
class StudyGroupSuggestion {
  final Level level;
  final String mentorUid;
  final List<LearnerCandidate> learners;

  const StudyGroupSuggestion({
    required this.level,
    required this.mentorUid,
    required this.learners,
  });
}

class GroupMatchResult {
  final List<StudyGroupSuggestion> groups;
  final List<LearnerCandidate> waitingForGroup;

  const GroupMatchResult({required this.groups, required this.waitingForGroup});
}

/// Groups learners only with others in the same F9 rate band. Groups contain
/// 4–6 learners; candidates with no stable [Rate] or no mentor remain waiting.
///
/// This creates suggestions only. Persisting assignments belongs on a trusted
/// backend/mentor action; a client must not be allowed to grant mentor access.
GroupMatchResult suggestStudyGroups({
  required Iterable<LearnerCandidate> learners,
  required List<String> mentorUids,
}) {
  if (mentorUids.any((uid) => uid.trim().isEmpty)) {
    throw ArgumentError('Mentor UIDs must not be empty.');
  }

  final eligible = <Level, List<LearnerCandidate>>{
    for (final level in Level.values) level: <LearnerCandidate>[],
  };
  final waiting = <LearnerCandidate>[];
  final seenUids = <String>{};
  for (final learner in learners) {
    if (learner.uid.trim().isEmpty || !seenUids.add(learner.uid)) {
      throw ArgumentError('Learner UIDs must be non-empty and unique.');
    }
    final rate = learner.rate;
    if (rate == null || mentorUids.isEmpty) {
      waiting.add(learner);
    } else {
      eligible[rate.level]!.add(learner);
    }
  }

  final groups = <StudyGroupSuggestion>[];
  for (final level in Level.values) {
    final candidates = eligible[level]!;
    // The largest subset that can be partitioned into valid groups.
    var assignedCount = candidates.length;
    var groupCount = 0;
    while (assignedCount >= 4) {
      groupCount = (assignedCount + 5) ~/ 6;
      if (assignedCount >= groupCount * 4) break;
      assignedCount--;
    }
    if (assignedCount < 4) {
      waiting.addAll(candidates);
      continue;
    }

    final baseSize = assignedCount ~/ groupCount;
    final largerGroups = assignedCount % groupCount;
    var cursor = 0;
    for (var i = 0; i < groupCount; i++) {
      final size = baseSize + (i < largerGroups ? 1 : 0);
      groups.add(
        StudyGroupSuggestion(
          level: level,
          mentorUid: mentorUids[groups.length % mentorUids.length],
          learners: List.unmodifiable(candidates.skip(cursor).take(size)),
        ),
      );
      cursor += size;
    }
    waiting.addAll(candidates.skip(assignedCount));
  }

  return GroupMatchResult(
    groups: List.unmodifiable(groups),
    waitingForGroup: List.unmodifiable(waiting),
  );
}
