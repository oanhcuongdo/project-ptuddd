const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

initializeApp();
const db = getFirestore();

async function notifyGroup(groupId, authorUid, title, body, submissionId) {
  const group = await db.collection('study_groups').doc(groupId).get();
  if (!group.exists) return;
  const recipients = [...new Set([
    group.get('mentorUid'),
    ...(group.get('memberUids') || []),
  ])].filter((uid) => uid && uid !== authorUid);
  const tokenSnapshots = await Promise.all(recipients.map((uid) =>
    db.collection('users').doc(uid).collection('private').doc('device').get(),
  ));
  const tokens = tokenSnapshots.flatMap((snapshot) => snapshot.get('tokens') || []);
  if (tokens.length === 0) return;
  await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: { submissionId },
    android: { priority: 'high' },
  });
}

exports.onSubmissionCreated = onDocumentCreated('submissions/{submissionId}', async (event) => {
  const submission = event.data?.data();
  if (!submission) return;
  await notifyGroup(
    submission.groupId,
    submission.learnerUid,
    'New study submission',
    submission.title || 'A learner shared new work.',
    event.params.submissionId,
  );
});

exports.onSubmissionCommentCreated = onDocumentCreated(
  'submissions/{submissionId}/comments/{commentId}',
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;
    const submission = await db.collection('submissions').doc(event.params.submissionId).get();
    if (!submission.exists) return;
    await notifyGroup(
      submission.get('groupId'),
      comment.authorUid,
      'New study comment',
      comment.text || 'A group member commented on a submission.',
      event.params.submissionId,
    );
  },
);
