import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/** Deliver newly created in-app notifications to the recipient's active devices. */
export const deliverNotification = functions.firestore
  .document('users/{userId}/notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (typeof data.title !== 'string' || typeof data.body !== 'string') return;
    const tokens = await admin.firestore().collection('users').doc(context.params.userId)
      .collection('fcm_tokens').where('isActive', '==', true).get();
    for (let offset = 0; offset < tokens.docs.length; offset += 500) {
      const batch = tokens.docs.slice(offset, offset + 500);
      const result = await admin.messaging().sendEachForMulticast({
        tokens: batch.map(doc => doc.id),
        notification: { title: data.title, body: data.body },
        data: {
          notificationId: context.params.notificationId,
          ...(typeof data.type === 'string' ? { type: data.type } : {}),
          ...(typeof data.workspaceId === 'string' ? { workspaceId: data.workspaceId } : {}),
          ...(typeof data.taskId === 'string' ? { taskId: data.taskId } : {}),
          ...(typeof data.invitationId === 'string' ? { invitationId: data.invitationId } : {}),
        },
      });
      const invalid = result.responses.flatMap((response, index) => {
        const code = response.error?.code;
        return !response.success && (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token')
          ? [batch[index].ref] : [];
      });
      if (invalid.length) {
        const updates = admin.firestore().batch();
        invalid.forEach(ref => updates.update(ref, { isActive: false }));
        await updates.commit();
      }
      if (result.failureCount > invalid.length) {
        functions.logger.warn('Some notification deliveries failed', { userId: context.params.userId, failureCount: result.failureCount });
      }
    }
  });

/**
 * Tell people when a task is assigned to them. Runs for every write of a task
 * and only reacts when the assignee changed to somebody other than the creator,
 * so editing a task never notifies twice. deliverNotification pushes the
 * resulting notification to the assignee's devices.
 */
export const notifyTaskAssignment = functions.firestore
  .document('workspaces/{workspaceId}/tasks/{taskId}')
  .onWrite(async (change, context) => {
    const after = change.after.data();
    if (!after) return;
    const assigneeId = after.assigneeId;
    if (typeof assigneeId !== 'string' || assigneeId.length === 0) return;
    if (assigneeId === change.before.data()?.assigneeId) return;
    if (assigneeId === after.ownerId) return;

    const title = typeof after.title === 'string' && after.title.length > 0 ? after.title : 'a task';
    await admin.firestore().collection('users').doc(assigneeId).collection('notifications').add({
      type: 'task_assigned',
      title: 'New task assigned',
      body: `You have been assigned "${title}".`,
      taskId: context.params.taskId,
      workspaceId: context.params.workspaceId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
