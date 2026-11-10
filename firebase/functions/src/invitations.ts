import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Create a workspace invitation (callable).
 * Only owner/admin/manager may invite. Expiration enforced server-side.
 */
export const createInvitation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
  }

  const { workspaceId, email, role } = data as {
    workspaceId?: string; email?: string; role?: string;
  };

  if (!workspaceId || !email || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'workspaceId, email and role are required.');
  }

  const validRoles = ['owner', 'admin', 'manager', 'member', 'viewer'];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid role.');
  }

  const callerUid = context.auth.uid;

  // Verify caller is a member with invite rights.
  const callerMember = await db.collection('workspaces').doc(workspaceId).collection('members').doc(callerUid).get();
  if (!callerMember.exists) {
    throw new functions.https.HttpsError('permission-denied', 'You are not a member of this workspace.');
  }
  const callerRole = callerMember.data()?.role as string;
  if (!['owner', 'admin', 'manager'].includes(callerRole)) {
    throw new functions.https.HttpsError('permission-denied', 'You cannot invite members.');
  }
  if (role === 'owner' && callerRole !== 'owner') {
    throw new functions.https.HttpsError('permission-denied', 'Only the owner can grant the owner role.');
  }

  // Expires 7 days from now.
  const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000));

  const invitationRef = db.collection('workspaces').doc(workspaceId).collection('invitations').doc();
  await invitationRef.set({
    email: email.toLowerCase(),
    role,
    status: 'pending',
    invitedBy: callerUid,
    workspaceId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt,
  });

  // Dispatch an invitation notification via FCM (server-side only).
  try {
    await sendNotificationToEmail(email, {
      title: 'Workspace invitation',
      body: `You have been invited to join a workspace as a ${role}.`,
      type: 'workspace_invitation',
      workspaceId,
    });
  } catch (e) {
    // Notification failure must not fail the invitation creation.
    functions.logger.warn('Failed to send invitation notification', e);
  }

  return { invitationId: invitationRef.id };
});

/**
 * Accept a workspace invitation (callable).
 * Validates expiration and membership server-side.
 */
export const acceptInvitation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
  }

  const { workspaceId, invitationId } = data as { workspaceId?: string; invitationId?: string };
  if (!workspaceId || !invitationId) {
    throw new functions.https.HttpsError('invalid-argument', 'workspaceId and invitationId are required.');
  }

  const callerUid = context.auth.uid;
  const callerEmail = context.auth.token.email as string;

  const invitationRef = db.collection('workspaces').doc(workspaceId).collection('invitations').doc(invitationId);
  const invitation = await invitationRef.get();
  if (!invitation.exists) {
    throw new functions.https.HttpsError('not-found', 'Invitation not found.');
  }

  const invData = invitation.data() as { email?: string; status?: string; role?: string; expiresAt?: admin.firestore.Timestamp };
  if (invData.email !== callerEmail?.toLowerCase()) {
    throw new functions.https.HttpsError('permission-denied', 'This invitation is not for your email address.');
  }
  if (invData.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'Invitation has already been processed.');
  }
  if (invData.expiresAt?.toDate() < new Date()) {
    throw new functions.https.HttpsError('failed-precondition', 'Invitation has expired.');
  }

  // Use a transaction: mark invitation accepted, add member record.
  await db.runTransaction(async (t) => {
    const current = await t.get(invitationRef);
    const currentData = current.data();
    if (!current.exists || currentData?.status !== 'pending' ||
        currentData?.email !== callerEmail?.toLowerCase() ||
        !(currentData?.expiresAt instanceof admin.firestore.Timestamp) ||
        currentData.expiresAt.toMillis() <= Date.now()) {
      throw new functions.https.HttpsError('failed-precondition', 'Invitation is no longer valid.');
    }
    const memberRef = db.collection('workspaces').doc(workspaceId).collection('members').doc(callerUid);
    const member = await t.get(memberRef);
    if (member.exists) {
      throw new functions.https.HttpsError('already-exists', 'You are already a workspace member.');
    }
    t.update(invitationRef, { status: 'accepted', acceptedAt: admin.firestore.FieldValue.serverTimestamp(), acceptedBy: callerUid });
    t.set(memberRef, {
      userId: callerUid,
      email: callerEmail,
      role: currentData.role ?? 'member',
      workspaceId,
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return { success: true, role: invData.role ?? 'member' };
});

/**
 * Change a member's role (callable). Only owner/admin may change roles.
 */
export const changeMemberRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
  }
  const { workspaceId, userId, role } = data as { workspaceId?: string; userId?: string; role?: string };
  if (!workspaceId || !userId || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'workspaceId, userId and role are required.');
  }

  if (!['owner', 'admin', 'manager', 'member', 'viewer'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid role.');
  }
  const callerUid = context.auth.uid;
  const callerMember = await db.collection('workspaces').doc(workspaceId).collection('members').doc(callerUid).get();
  if (!callerMember.exists) {
    throw new functions.https.HttpsError('permission-denied', 'You are not a member of this workspace.');
  }
  const callerRole = callerMember.data()?.role as string;
  if (!['owner', 'admin'].includes(callerRole)) {
    throw new functions.https.HttpsError('permission-denied', 'Only owners and admins can change roles.');
  }

  const targetMember = await db.collection('workspaces').doc(workspaceId).collection('members').doc(userId).get();
  if (!targetMember.exists) {
    throw new functions.https.HttpsError('not-found', 'Member not found.');
  }

  if (callerRole !== 'owner' && (role === 'owner' || targetMember.data()?.role === 'owner')) {
    throw new functions.https.HttpsError('permission-denied', 'Only the owner can change an owner role.');
  }
  if (userId === callerUid && role !== callerRole) {
    throw new functions.https.HttpsError('permission-denied', 'You cannot change your own role.');
  }

  await db.collection('workspaces').doc(workspaceId).collection('members').doc(userId).update({ role });
  return { success: true };
});

/**
 * Send a task assignment notification (callable).
 */
export const sendTaskAssignmentNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
  }
  const { taskId, assigneeId, workspaceId } = data as { taskId?: string; assigneeId?: string; workspaceId?: string };
  if (!taskId || !assigneeId || !workspaceId) {
    throw new functions.https.HttpsError('invalid-argument', 'taskId, assigneeId and workspaceId are required.');
  }

  const workspaceRef = db.collection('workspaces').doc(workspaceId);
  const [caller, task, assignee] = await Promise.all([
    workspaceRef.collection('members').doc(context.auth.uid).get(),
    workspaceRef.collection('tasks').doc(taskId).get(),
    workspaceRef.collection('members').doc(assigneeId).get(),
  ]);
  if (!caller.exists || !['owner', 'admin', 'manager'].includes(caller.data()?.role) ||
      !task.exists || task.data()?.assigneeId !== assigneeId || !assignee.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Not authorized to notify this assignee.');
  }

  await db.collection('users').doc(assigneeId).collection('notifications').add({
    type: 'task_assigned',
    title: 'New task assigned',
    body: 'You have been assigned a new task.',
    taskId,
    workspaceId,
    assignedBy: context.auth.uid,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

/**
 * Clean expired invitations (callable or scheduled).
 */
export const cleanExpiredInvitations = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
  }
  const callerUid = context.auth.uid;
  // Only allow the caller to clean invitations in workspaces they own.
  const workspaces = await db.collectionGroup('members').where('userId', '==', callerUid).where('role', '==', 'owner').get();
  const ownedIds = workspaces.docs.map(d => d.ref.parent.parent?.id).filter(Boolean) as string[];

  let deleted = 0;
  for (const wsId of ownedIds) {
    const snap = await db.collection('workspaces').doc(wsId).collection('invitations')
      .where('status', '==', 'pending')
      .where('expiresAt', '<', admin.firestore.Timestamp.fromDate(new Date())).get();
    const batch = db.batch();
    snap.docs.forEach(d => { batch.delete(d.ref); deleted++; });
    if (deleted > 0) await batch.commit();
  }
  return { deleted };
});

/**
 * Helper: look up FCM tokens for an email and send a notification.
 * (Implementation relies on a user_fcm_tokens collection maintained by the client.)
 */
async function sendNotificationToEmail(email: string, payload: { title: string; body: string; type: string; workspaceId?: string }) {
  const tokensSnap = await db.collectionGroup('fcm_tokens').where('email', '==', email.toLowerCase()).limit(5).get();
  const tokens = tokensSnap.docs.map(d => d.id).filter(Boolean);
  if (tokens.length === 0) return;
  await admin.messaging().sendMulticast({
    tokens,
    notification: { title: payload.title, body: payload.body },
    data: { type: payload.type, ...(payload.workspaceId ? { workspaceId: payload.workspaceId } : {}) },
  });
}
