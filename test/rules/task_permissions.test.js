const { test, before, after } = require('node:test');
const fs = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, deleteDoc, deleteField } = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'flowtop-task-rules', firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') } });
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'workspaces/w'), { ownerId: 'owner', name: 'Workspace' });
    for (const [uid, role] of [['owner', 'owner'], ['alice', 'member'], ['viewer', 'viewer']]) {
      await setDoc(doc(db, `workspaces/w/members/${uid}`), { userId: uid, workspaceId: 'w', role });
    }
    await setDoc(doc(db, 'workspaces/w/tasks/t'), { ownerId: 'alice', workspaceId: 'w', title: 'Task', status: 'todo' });
    await setDoc(doc(db, 'users/alice/notifications/n'), { title: 'Notice', read: false });
  });
});
after(async () => { if (env) await env.cleanup(); });

test('only workspace members may read tasks', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const outsider = env.authenticatedContext('outsider').firestore();
  await assertSucceeds(getDoc(doc(alice, 'workspaces/w/tasks/t')));
  await assertFails(getDoc(doc(outsider, 'workspaces/w/tasks/t')));
  await assertFails(deleteDoc(doc(outsider, 'workspaces/w/tasks/t')));
});
test('task owners may update content but cannot remove protected fields', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(updateDoc(doc(db, 'workspaces/w/tasks/t'), { title: 'Updated' }));
  await assertFails(updateDoc(doc(db, 'workspaces/w/tasks/t'), { ownerId: deleteField() }));
  await assertFails(updateDoc(doc(db, 'workspaces/w/tasks/t'), { workspaceId: deleteField() }));
});
test('viewer cannot create tasks or modify subtasks', async () => {
  const db = env.authenticatedContext('viewer').firestore();
  await assertFails(setDoc(doc(db, 'workspaces/w/tasks/new'), { title: 'New', ownerId: 'viewer', workspaceId: 'w' }));
  await assertFails(setDoc(doc(db, 'workspaces/w/tasks/t/subtasks/s'), { title: 'subtask' }));
});
test('notification content is server-created and only read state is editable', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice/notifications/fake'), { title: 'Fake', read: false }));
  await assertFails(updateDoc(doc(db, 'users/alice/notifications/n'), { title: 'Fake' }));
  await assertSucceeds(updateDoc(doc(db, 'users/alice/notifications/n'), { read: true }));
});
