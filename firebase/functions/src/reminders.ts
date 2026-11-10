import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Send scheduled task reminder notifications.
 * Intended to be triggered by a scheduled function (e.g. every minute) or a
 * Cloud Tasks queue; here exposed as a callable for demonstration.
 */
export const sendTaskReminderNotifications = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
  }

  const now = new Date();
  // Remind for tasks due within the next hour that aren't done.
  const soon = new Date(Date.now() + 60 * 60 * 1000);

  const tasksSnap = await db.collectionGroup('tasks')
    .where('status', '!=', 'done')
    .where('dueDate', '>=', admin.firestore.Timestamp.fromDate(now))
    .where('dueDate', '<=', admin.firestore.Timestamp.fromDate(soon))
    .get();

  const notifications: { [workspaceId: string]: string[] } = {};

  for (const doc of tasksSnap.docs) {
    const task = doc.data() as { ownerId?: string; assigneeId?: string; title?: string; workspaceId?: string };
    const targets = new Set<string>();
    if (task.ownerId) targets.add(task.ownerId);
    if (task.assigneeId) targets.add(task.assigneeId);
    for (const uid of targets) {
      await db.collection('users').doc(uid).collection('notifications').add({
        type: 'task_reminder',
        title: 'Task reminder',
        body: `The task "${task.title ?? 'Untitled task"}' is due soon.`,
        taskId: doc.id,
        workspaceId: task.workspaceId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  return { notified: tasksSnap.size };
});
