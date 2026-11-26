import 'package:flutter_test/flutter_test.dart';
import 'package:english_pronunciation_app/scoring/rate.dart';
import 'package:english_pronunciation_app/services/group_matcher.dart';

void main() {
  const beginner = Rate(40, Level.beginner, 10);
  const intermediate = Rate(75, Level.intermediate, 10);

  List<LearnerCandidate> learners(
    int count,
    Rate rate, {
    String prefix = 'u',
  }) => List.generate(
    count,
    (index) => LearnerCandidate(
      uid: '$prefix$index',
      displayName: 'Learner $index',
      rate: rate,
    ),
  );

  test('creates balanced groups of four to six at the same rate level', () {
    final result = suggestStudyGroups(
      learners: [
        ...learners(11, beginner),
        ...learners(5, intermediate, prefix: 'i'),
      ],
      mentorUids: const ['mentor-a', 'mentor-b'],
    );

    expect(result.groups.map((group) => group.learners.length), [6, 5, 5]);
    expect(result.groups.map((group) => group.level), [
      Level.beginner,
      Level.beginner,
      Level.intermediate,
    ]);
    expect(result.groups.map((group) => group.mentorUid), [
      'mentor-a',
      'mentor-b',
      'mentor-a',
    ]);
    expect(result.waitingForGroup, isEmpty);
  });

  test(
    'does not create undersized groups and returns remainder to waitlist',
    () {
      final result = suggestStudyGroups(
        learners: learners(7, beginner),
        mentorUids: const ['mentor-a'],
      );

      expect(result.groups, hasLength(1));
      expect(result.groups.single.learners, hasLength(6));
      expect(result.waitingForGroup, hasLength(1));
    },
  );

  test('learners without enough attempts or without a mentor wait', () {
    final candidates = [
      ...learners(3, beginner),
      const LearnerCandidate(
        uid: 'new',
        displayName: 'New learner',
        rate: null,
      ),
    ];

    expect(
      suggestStudyGroups(learners: candidates, mentorUids: const ['mentor']),
      isA<GroupMatchResult>()
          .having((r) => r.groups, 'groups', isEmpty)
          .having((r) => r.waitingForGroup, 'waiting learners', hasLength(4)),
    );
    final noMentor = suggestStudyGroups(
      learners: learners(4, beginner),
      mentorUids: const [],
    );
    expect(noMentor.groups, isEmpty);
    expect(noMentor.waitingForGroup, hasLength(4));
  });

  test('rejects duplicate learner identities', () {
    expect(
      () => suggestStudyGroups(
        learners: [
          const LearnerCandidate(
            uid: 'same',
            displayName: 'One',
            rate: beginner,
          ),
          const LearnerCandidate(
            uid: 'same',
            displayName: 'Two',
            rate: beginner,
          ),
        ],
        mentorUids: const ['mentor'],
      ),
      throwsArgumentError,
    );
  });
}
