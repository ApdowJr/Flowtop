import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const INVITATION_LIFETIME_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * Create a workspace invitation (callable).
 * Only owner/admin/manager may invite. Expiration enforced server-side.
 *
 * The invitation stores the workspace and inviter names, because the invitee
 * is not a member yet and therefore cannot read the workspace document.
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

  const normalizedEmail = email.trim().toLowerCase();
  if (!EMAIL_PATTERN.test(normalizedEmail)) {
    throw new functions.https.HttpsError('invalid-argument', 'Enter a valid email address.');
  }

  const validRoles = ['owner', 'admin', 'manager', 'member', 'viewer'];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid role.');
  }

  const callerUid = context.auth.uid;
  const callerEmail = (context.auth.token.email as string | undefined)?.toLowerCase();
  if (callerEmail && callerEmail === normalizedEmail) {
    throw new functions.https.HttpsError('invalid-argument', 'You cannot invite yourself.');
  }

  const workspaceRef = db.collection('workspaces').doc(workspaceId);

  // Verify caller is a member with invite rights.
  const callerMember = await workspaceRef.collection('members').doc(callerUid).get();
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

  // Refuse duplicates: people who already belong, and invitations still open.
  const [workspaceDoc, existingMember, existingInvitations] = await Promise.all([
    workspaceRef.get(),
    workspaceRef.collection('members').where('email', '==', normalizedEmail).limit(1).get(),
    workspaceRef.collection('invitations').where('email', '==', normalizedEmail).get(),
  ]);
  if (!existingMember.empty) {
    throw new functions.https.HttpsError('already-exists', 'This person is already a member of the workspace.');
  }
  const nowMs = Date.now();
  const hasOpenInvitation = existingInvitations.docs.some((doc) => {
    const invitation = doc.data();
    const expiresAt = invitation.expiresAt as admin.firestore.Timestamp | undefined;
    return invitation.status === 'pending' && !!expiresAt && expiresAt.toMillis() > nowMs;
  });
  if (hasOpenInvitation) {
    throw new functions.https.HttpsError('already-exists', 'This person already has a pending invitation.');
  }

  const inviterName = await displayNameOf(callerUid, context.auth.token.name as string | undefined);
  const workspaceName = (workspaceDoc.data()?.name as string | undefined) ?? 'a workspace';

  const expiresAt = admin.firestore.Timestamp.fromDate(new Date(nowMs + INVITATION_LIFETIME_MS));

  const invitationRef = workspaceRef.collection('invitations').doc();
  await invitationRef.set({
    email: normalizedEmail,
    role,
    status: 'pending',
    invitedBy: callerUid,
    ...(inviterName ? { invitedByName: inviterName } : {}),
    workspaceId,
    workspaceName,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt,
  });

  // Tell the invitee when they already have an account. Writing the in-app
  // notification is enough: deliverNotification pushes it to their devices.
  await notifyInvitee(normalizedEmail, {
    title: 'Workspace invitation',
    body: `${inviterName ?? 'Someone'} invited you to join ${workspaceName} as ${role}.`,
    workspaceId,
    invitationId: invitationRef.id,
  });

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

  // Invitations belong to an email address, and anybody can register with an
  // address that is not theirs. Only a verified address may claim one.
  if (context.auth.token.email_verified !== true) {
    throw new functions.https.HttpsError('failed-precondition', 'Verify your email address before accepting invitations.');
  }

  const callerUid = context.auth.uid;
  const callerEmail = context.auth.token.email as string;
  const callerName = await displayNameOf(callerUid, context.auth.token.name as string | undefined);

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
      email: callerEmail?.toLowerCase(),
      ...(callerName ? { displayName: callerName } : {}),
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
    if (snap.empty) continue;
    const batch = db.batch();
    snap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
    deleted += snap.size;
  }
  return { deleted };
});

/**
 * Best-effort display name for a user: the Auth profile first, then the name
 * claim of the caller's token.
 */
async function displayNameOf(uid: string, tokenName?: string): Promise<string | undefined> {
  try {
    const record = await admin.auth().getUser(uid);
    return record.displayName || tokenName || undefined;
  } catch (e) {
    functions.logger.warn('Could not read the display name of a user', e);
    return tokenName || undefined;
  }
}

/**
 * Create an in-app notification for the person behind [email], if they already
 * have an account. The deliverNotification trigger forwards it as a push
 * notification. A failure never fails the invitation itself.
 */
async function notifyInvitee(
  email: string,
  payload: { title: string; body: string; workspaceId: string; invitationId: string },
): Promise<void> {
  try {
    const invitee = await admin.auth().getUserByEmail(email);
    await db.collection('users').doc(invitee.uid).collection('notifications').add({
      type: 'workspace_invitation',
      title: payload.title,
      body: payload.body,
      workspaceId: payload.workspaceId,
      invitationId: payload.invitationId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    if ((e as { code?: string }).code !== 'auth/user-not-found') {
      functions.logger.warn('Failed to notify the invitee', e);
    }
  }
}
