// Run with the Firestore emulator: firebase emulators:exec --only firestore
// "node --test test/rules/workspace_membership.test.js"
const { test, before, after } = require('node:test');
const fs = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, collectionGroup, query, where, getDocs } = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'flowtop-workspace-rules',
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'workspaces/a/members/alice'), { userId: 'alice', workspaceId: 'a', role: 'member' });
    await setDoc(doc(db, 'workspaces/b/members/bob'), { userId: 'bob', workspaceId: 'b', role: 'member' });
  });
});
after(async () => { if (env) await env.cleanup(); });

test('users can query only their own workspace memberships', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDocs(query(collectionGroup(db, 'members'), where('userId', '==', 'alice'))));
  await assertFails(getDocs(query(collectionGroup(db, 'members'), where('userId', '==', 'bob'))));
  await assertFails(getDocs(collectionGroup(db, 'members')));
});
