// Run with the Firestore emulator: firebase emulators:exec --only firestore
// "node --test test/rules/invitations.test.js"
const { test, before, beforeEach, after } = require('node:test');
const fs = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, getDoc, updateDoc, deleteDoc, writeBatch, collectionGroup, query, where, getDocs, Timestamp,
} = require('firebase/firestore');

let env;
const inOneDay = () => Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
const aSecondAgo = () => Timestamp.fromMillis(Date.now() - 1000);

const invitation = (email, overrides = {}) => ({
  email,
  role: 'member',
  status: 'pending',
  workspaceId: 'w',
  invitedBy: 'owner',
  expiresAt: inOneDay(),
  ...overrides,
});

const verified = (uid, email) => env.authenticatedContext(uid, { email, email_verified: true }).firestore();
const unverified = (uid, email) => env.authenticatedContext(uid, { email, email_verified: false }).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'flowtop-invitation-rules',
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
});
after(async () => { if (env) await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'workspaces/w'), { ownerId: 'owner', name: 'Studio' });
    for (const [uid, role] of [['owner', 'owner'], ['admin', 'admin'], ['manager', 'manager'], ['member', 'member'], ['viewer', 'viewer']]) {
      await setDoc(doc(db, `workspaces/w/members/${uid}`), { userId: uid, workspaceId: 'w', role });
    }
    await setDoc(doc(db, 'workspaces/w/invitations/amina'), invitation('amina@example.com'));
    await setDoc(doc(db, 'workspaces/w/invitations/omar'), invitation('omar@example.com'));
  });
});

test('invitees can list the invitations addressed to their verified email', async () => {
  const db = verified('amina', 'amina@example.com');
  const snapshot = await assertSucceeds(
    getDocs(query(collectionGroup(db, 'invitations'), where('email', '==', 'amina@example.com'))),
  );
  if (snapshot.size !== 1) throw new Error(`expected one invitation, got ${snapshot.size}`);
  await assertFails(getDocs(query(collectionGroup(db, 'invitations'), where('email', '==', 'omar@example.com'))));
  await assertFails(getDocs(collectionGroup(db, 'invitations')));
});

test('an email with capital letters in the token still matches the lower-case invitation', async () => {
  const db = verified('amina', 'Amina@Example.com');
  await assertSucceeds(
    getDocs(query(collectionGroup(db, 'invitations'), where('email', '==', 'amina@example.com'))),
  );
});

test('an unverified email can neither list nor answer invitations', async () => {
  const db = unverified('mallory', 'amina@example.com');
  await assertFails(
    getDocs(query(collectionGroup(db, 'invitations'), where('email', '==', 'amina@example.com'))),
  );
  await assertFails(updateDoc(doc(db, 'workspaces/w/invitations/amina'), { status: 'declined' }));
});

test('an invitee may decline but cannot change anything else or touch other invitations', async () => {
  const db = verified('amina', 'amina@example.com');
  await assertFails(updateDoc(doc(db, 'workspaces/w/invitations/amina'), { role: 'admin' }));
  await assertFails(updateDoc(doc(db, 'workspaces/w/invitations/amina'), { status: 'declined', role: 'admin' }));
  await assertFails(updateDoc(doc(db, 'workspaces/w/invitations/omar'), { status: 'declined' }));
  await assertSucceeds(updateDoc(doc(db, 'workspaces/w/invitations/amina'), { status: 'declined' }));
});

test('an expired invitation can no longer be answered', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'workspaces/w/invitations/old'), invitation('amina@example.com', { expiresAt: aSecondAgo() }));
  });
  const db = verified('amina', 'amina@example.com');
  await assertFails(updateDoc(doc(db, 'workspaces/w/invitations/old'), { status: 'declined' }));
});

test('members read their workspace invitations, outsiders do not', async () => {
  await assertSucceeds(getDoc(doc(verified('member', 'member@example.com'), 'workspaces/w/invitations/amina')));
  await assertFails(getDoc(doc(verified('outsider', 'outsider@example.com'), 'workspaces/w/invitations/amina')));
});

test('managers may revoke invitations, regular members may not', async () => {
  await assertFails(deleteDoc(doc(verified('member', 'member@example.com'), 'workspaces/w/invitations/amina')));
  await assertSucceeds(deleteDoc(doc(verified('manager', 'manager@example.com'), 'workspaces/w/invitations/amina')));
});

test('a regular member can leave a workspace but cannot remove somebody else', async () => {
  const db = verified('member', 'member@example.com');
  await assertFails(deleteDoc(doc(db, 'workspaces/w/members/viewer')));
  await assertFails(deleteDoc(doc(db, 'workspaces/w/members/manager')));
  await assertSucceeds(deleteDoc(doc(db, 'workspaces/w/members/member')));
});

test('the owner can never leave and nobody else can remove the owner', async () => {
  await assertFails(deleteDoc(doc(verified('owner', 'owner@example.com'), 'workspaces/w/members/owner')));
  await assertFails(deleteDoc(doc(verified('admin', 'admin@example.com'), 'workspaces/w/members/owner')));
  await assertFails(deleteDoc(doc(verified('member', 'member@example.com'), 'workspaces/w/members/owner')));
});

test('admins can still remove regular members', async () => {
  await assertSucceeds(deleteDoc(doc(verified('admin', 'admin@example.com'), 'workspaces/w/members/viewer')));
});

test('the owner can delete the workspace together with every membership, including their own', async () => {
  const db = verified('owner', 'owner@example.com');
  const batch = writeBatch(db);
  for (const uid of ['owner', 'admin', 'manager', 'member', 'viewer']) {
    batch.delete(doc(db, `workspaces/w/members/${uid}`));
  }
  batch.delete(doc(db, 'workspaces/w/invitations/amina'));
  batch.delete(doc(db, 'workspaces/w/invitations/omar'));
  batch.delete(doc(db, 'workspaces/w'));
  await assertSucceeds(batch.commit());
});

test('nobody else may delete the workspace or the owner record as part of a batch', async () => {
  const db = verified('admin', 'admin@example.com');
  const batch = writeBatch(db);
  batch.delete(doc(db, 'workspaces/w/members/owner'));
  batch.delete(doc(db, 'workspaces/w'));
  await assertFails(batch.commit());
});
