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
