import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Send scheduled task reminder notifications.
 * Runs hourly to cover the next hour without exposing a global callable endpoint.
 */
export const sendTaskReminderNotifications = functions.pubsub.schedule('every 60 minutes').onRun(async () => {

  const now = new Date();
  // Remind for tasks due within the next hour that aren't done.
  const soon = new Date(Date.now() + 60 * 60 * 1000);

  const tasksSnap = await db.collectionGroup('tasks')
    .where('dueDate', '>=', admin.firestore.Timestamp.fromDate(now))
    .where('dueDate', '<=', admin.firestore.Timestamp.fromDate(soon))
    .get();

  for (const doc of tasksSnap.docs) {
    const task = doc.data() as { ownerId?: string; assigneeId?: string; title?: string; workspaceId?: string };
    if (doc.data().status === 'done') continue;
    const targets = new Set<string>();
    if (task.ownerId) targets.add(task.ownerId);
    if (task.assigneeId) targets.add(task.assigneeId);
    for (const uid of targets) {
      await db.collection('users').doc(uid).collection('notifications').add({
        type: 'task_reminder',
        title: 'Task reminder',
        body: `The task "${task.title ?? 'Untitled task'}" is due soon.`,
        taskId: doc.id,
        workspaceId: task.workspaceId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  return null;
});
