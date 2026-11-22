import 'package:cloud_firestore/cloud_firestore.dart';

import '../scoring/rate.dart';
import 'firebase_backend.dart';
import 'group_matcher.dart';

/// Firestore persistence and live queries for mentor-managed F10 groups.
class FirestoreGroupRepository {
  final FirebaseFirestore _store;

  FirestoreGroupRepository({FirebaseFirestore? store})
    : _store = store ?? FirebaseFirestore.instance;

  Future<GroupMatchResult> suggestAndAssignGroups(String mentorUid) async {
    final candidates = <LearnerCandidate>[];
    for (final level in Level.values) {
      final snapshot = await _store
          .collection('users')
          .where('role', isEqualTo: 'learner')
          .where('rateLevel', isEqualTo: level.label)
          .where('groupId', isNull: true)
          .get();
      for (final document in snapshot.docs) {
        final data = document.data();
        final rateValue = data['rate'];
        if (rateValue is! num) continue;
        candidates.add(
          LearnerCandidate(
            uid: document.id,
            displayName: data['displayName'] as String? ?? 'Learner',
            rate: Rate(
              rateValue.toDouble(),
              level,
              data['attemptCount'] as int? ?? 0,
            ),
          ),
        );
      }
    }
    final suggestion = suggestStudyGroups(
      learners: candidates,
      mentorUids: [mentorUid],
    );
    final batch = _store.batch();
    for (final group in suggestion.groups) {
      final groupRef = _store.collection('study_groups').doc();
      batch.set(groupRef, {
        'level': group.level.label,
        'mentorUid': mentorUid,
        'memberUids': group.learners.map((learner) => learner.uid).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final learner in group.learners) {
        batch.update(_store.collection('users').doc(learner.uid), {
          'groupId': groupRef.id,
        });
      }
    }
    if (suggestion.groups.isNotEmpty) await batch.commit();
    return suggestion;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGroup(String groupId) =>
      _store.collection('study_groups').doc(groupId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMentorGroups(String uid) =>
      _store
          .collection('study_groups')
          .where('mentorUid', isEqualTo: uid)
          .snapshots();

  Future<List<AccountProfile>> loadMembers(List<String> uids) async {
    if (uids.isEmpty) return const [];
    final docs = await Future.wait(
      uids.map((uid) => _store.collection('users').doc(uid).get()),
    );
    return [
      for (final doc in docs)
        if (doc.exists) AccountProfile.fromDocument(doc.id, doc.data()!),
    ];
  }
}
