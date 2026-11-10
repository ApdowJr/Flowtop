const {
  assertFails,
  assertSucceeds,
  initializeTestApp,
  initializeAdminApp,
  clearFirestoreData,
} = require('@firebase/rules-unit-testing');
const firebase = require('@firebase/testing');

const PROJECT_ID = 'flowtop-emulator';

describe('Flowtop Firestore Security Rules', () => {
  beforeAll(async () => {
    await clearFirestoreData({ projectId: PROJECT_ID });
  });

  afterAll(async () => {
    await Promise.all(firebase.apps().map(app => app.delete()));
  });

  // Helper to create an authenticated app for a given UID/email.
  function authedApp(uid, email = null) {
    return initializeTestApp({
      projectId: PROJECT_ID,
      auth: { uid: uid, token: { email: email || `${uid}@example.com` } },
    });
  }

  describe('users collection', () => {
    test('user can read own profile', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertSucceeds(db.doc('users/alice').get());
    });

    test('user cannot read another user profile', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertFails(db.doc('users/bob').get());
    });

    test('user cannot write protected uid field', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertFails(db.doc('users/alice').set({ uid: 'bob' }));
    });

    test('user cannot change emailVerified', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('users/alice').set({ uid: 'alice', emailVerified: false });
      await assertFails(db.doc('users/alice').update({ emailVerified: true }));
    });

    test('user can update own displayName', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('users/alice').set({ uid: 'alice', displayName: 'Alice' });
      await assertSucceeds(db.doc('users/alice').update({ displayName: 'Alice Smith' }));
    });
  });

  describe('workspaces collection', () => {
    test('workspace member can read workspace', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws1/members/alice').set({ role: 'member', userId: 'alice' });
      await assertSucceeds(db.doc('workspaces/ws1').get());
    });

    test('non-member cannot read workspace', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await assertFails(db.doc('workspaces/ws1').get());
    });

    test('member cannot update ownerId', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws1/members/alice').set({ role: 'member', userId: 'alice' });
      await assertFails(db.doc('workspaces/ws1').update({ ownerId: 'someone-else' }));
    });

    test('owner can update workspace', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws2/members/owner1').set({ role: 'owner', userId: 'owner1' });
      await assertSucceeds(db.doc('workspaces/ws2').update({ name: 'Renamed' }));
    });

    test('non-owner cannot delete workspace', async () => {
      const member = authedApp('member1', 'member@example.com');
      const db = member.firestore();
      await db.doc('workspaces/ws3/members/member1').set({ role: 'member', userId: 'member1' });
      await assertFails(db.doc('workspaces/ws3').delete());
    });

    test('owner can delete workspace', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws4/members/owner1').set({ role: 'owner', userId: 'owner1' });
      await assertSucceeds(db.doc('workspaces/ws4').delete());
    });
  });

  describe('workspace_members subcollection', () => {
    test('member cannot promote themselves', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws5/members/alice').set({ role: 'member', userId: 'alice' });
      await assertFails(db.doc('workspaces/ws5/members/alice').update({ role: 'admin' }));
    });

    test('owner can change another member role', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws6/members/owner1').set({ role: 'owner', userId: 'owner1' });
      await db.doc('workspaces/ws6/members/bob').set({ role: 'member', userId: 'bob' });
      await assertSucceeds(db.doc('workspaces/ws6/members/bob').update({ role: 'manager' }));
    });

    test('admin can change another member role', async () => {
      const admin = authedApp('admin1', 'admin@example.com');
      const db = admin.firestore();
      await db.doc('workspaces/ws7/members/admin1').set({ role: 'admin', userId: 'admin1' });
      await db.doc('workspaces/ws7/members/bob').set({ role: 'member', userId: 'bob' });
      await assertSucceeds(db.doc('workspaces/ws7/members/bob').update({ role: 'viewer' }));
    });

    test('non-member cannot create member record', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await assertFails(db.doc('workspaces/ws8/members/mallory').set({ role: 'member', userId: 'mallory' }));
    });

    test('member cannot remove themselves if they are the only owner', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws9/members/owner1').set({ role: 'owner', userId: 'owner1' });
      await assertFails(db.doc('workspaces/ws9/members/owner1').delete());
    });
  });

  describe('invitations', () => {
    test('only members can create invitations', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await assertFails(db.doc('workspaces/ws10/invitations/inv1').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      }));
    });

    test('invitation with past expiration is rejected', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws11/members/owner1').set({ role: 'owner', userId: 'owner1' });
      await assertFails(db.doc('workspaces/ws11/invitations/inv2').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000)),
      }));
    });

    test('non-owner cannot assign owner role via invitation', async () => {
      const manager = authedApp('manager1', 'manager@example.com');
      const db = manager.firestore();
      await db.doc('workspaces/ws12/members/manager1').set({ role: 'manager', userId: 'manager1' });
      await assertFails(db.doc('workspaces/ws12/invitations/inv3').set({
        email: 'bob@example.com',
        role: 'owner',
        status: 'pending',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      }));
    });

    test('invited user can accept invitation (status only)', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws13/members/owner1').set({ role: 'owner', userId: 'owner1' });
      await db.doc('workspaces/ws13/invitations/inv4').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws13',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      // Bob can update the status to accepted
      await assertSucceeds(dbBob.doc('workspaces/ws13/invitations/inv4').update({ status: 'accepted' }));
    });

    test('invited user cannot change role in invitation', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws14/members/owner1').set({ role: 'owner', userId: 'owner1' });
      await db.doc('workspaces/ws14/invitations/inv5').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws14',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      // Bob cannot change the role
      await assertFails(dbBob.doc('workspaces/ws14/invitations/inv5').update({ role: 'admin' }));
    });
  });

  describe('tasks', () => {
    test('workspace member can read tasks', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws15/members/alice').set({ role: 'member', userId: 'alice' });
      await assertSucceeds(db.doc('workspaces/ws15/tasks/t1').get());
    });

    test('non-member cannot read tasks', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await assertFails(db.doc('workspaces/ws15/tasks/t1').get());
    });

    test('owner can delete own task', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws16/members/alice').set({ role: 'owner', userId: 'alice' });
      await db.doc('workspaces/ws16/tasks/t2').set({
        ownerId: 'alice',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws16',
      });
      await assertSucceeds(db.doc('workspaces/ws16/tasks/t2').delete());
    });

    test('task owner can update own task', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws17/members/alice').set({ role: 'member', userId: 'alice' });
      await db.doc('workspaces/ws17/tasks/t3').set({
        ownerId: 'alice',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws17',
      });
      await assertSucceeds(db.doc('workspaces/ws17/tasks/t3').update({ status: 'done' }));
    });

    test('non-owner cannot change task ownerId', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws18/members/alice').set({ role: 'member', userId: 'alice' });
      await db.doc('workspaces/ws18/tasks/t4').set({
        ownerId: 'alice',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws18',
      });
      await assertFails(db.doc('workspaces/ws18/tasks/t4').update({ ownerId: 'bob' }));
    });

    test('admin can change any task ownerId', async () => {
      const admin = authedApp('admin1', 'admin@example.com');
      const db = admin.firestore();
      await db.doc('workspaces/ws19/members/admin1').set({ role: 'admin', userId: 'admin1' });
      await db.doc('workspaces/ws19/tasks/t5').set({
        ownerId: 'alice',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws19',
      });
      await assertSucceeds(db.doc('workspaces/ws19/tasks/t5').update({ ownerId: 'bob' }));
    });

    test('member cannot change workspaceId of task', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws20/members/alice').set({ role: 'member', userId: 'alice' });
      await db.doc('workspaces/ws20/tasks/t6').set({
        ownerId: 'alice',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws20',
      });
      await assertFails(db.doc('workspaces/ws20/tasks/t6').update({ workspaceId: 'ws21' }));
    });
  });

  describe('subtasks', () => {
    test('workspace member can read subtasks', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws21/members/alice').set({ role: 'member', userId: 'alice' });
      await assertSucceeds(db.doc('workspaces/ws21/tasks/t1/subtasks/s1').get());
    });

    test('non-member cannot read subtasks', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await assertFails(db.doc('workspaces/ws21/tasks/t1/subtasks/s1').get());
    });
  });

  describe('FCM tokens', () => {
    test('user can read own FCM tokens', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertSucceeds(db.doc('users/alice/fcm_tokens/token1').get());
    });

    test('user cannot read another user FCM tokens', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertFails(db.doc('users/bob/fcm_tokens/token1').get());
    });

    test('user can create own FCM token', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertSucceeds(db.doc('users/alice/fcm_tokens/token2').set({
        userId: 'alice',
        token: 'token2',
        platform: 'android',
        isActive: true,
      }));
    });

    test('user cannot create FCM token for another user', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertFails(db.doc('users/bob/fcm_tokens/token3').set({
        userId: 'bob',
        token: 'token3',
        platform: 'android',
        isActive: true,
      }));
    });
  });

  describe('notifications', () => {
    test('user can read own notifications', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertSucceeds(db.doc('users/alice/notifications/n1').get());
    });

    test('user cannot read another user notifications', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertFails(db.doc('users/bob/notifications/n1').get());
    });
  });

  describe('workspace owner membership bootstrap (security)', () => {
    test('non-owner cannot make themselves owner of an existing workspace', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      // Mallory is a member (not owner) of an existing workspace owned by someone else.
      await db.doc('workspaces/ws30/members/mallory').set({ role: 'member', userId: 'mallory', workspaceId: 'ws30' });
      // The workspace doc is owned by 'owner1', not Mallory.
      await db.doc('workspaces/ws30').set({ ownerId: 'owner1', name: 'Mallorys Target' });
      // Mallory tries to bootstrap themselves as owner via the create-member exception.
      await assertFails(db.doc('workspaces/ws30/members/mallory').set({
        userId: 'mallory',
        role: 'owner',
        workspaceId: 'ws30',
      }));
    });

    test('member cannot create owner-role member record for another user', async () => {
      const member = authedApp('member1', 'member@example.com');
      const db = member.firestore();
      await db.doc('workspaces/ws31/members/member1').set({ role: 'member', userId: 'member1', workspaceId: 'ws31' });
      await db.doc('workspaces/ws31').set({ ownerId: 'owner1', name: 'ws31' });
      // Member tries to create an owner-role membership for someone else.
      await assertFails(db.doc('workspaces/ws31/members/bob').set({
        userId: 'bob',
        role: 'owner',
        workspaceId: 'ws31',
      }));
    });

    test('member document ID must match userId field', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await db.doc('workspaces/ws32/members/mallory').set({ role: 'member', userId: 'mallory', workspaceId: 'ws32' });
      await db.doc('workspaces/ws32').set({ ownerId: 'mallory', name: 'ws32' });
      // Mallory tries to create a member doc with ID 'bob' but userId 'mallory'.
      await assertFails(db.doc('workspaces/ws32/members/bob').set({
        userId: 'mallory',
        role: 'member',
        workspaceId: 'ws32',
      }));
    });

    test('owner can create their own owner membership for newly created workspace (bootstrap)', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      // Step 1: create workspace doc (ownerId bound to auth UID).
      await db.doc('workspaces/ws33').set({ ownerId: 'owner1', name: 'New Workspace' });
      // Step 2: owner creates their own owner membership record (bootstrap exception).
      await assertSucceeds(db.doc('workspaces/ws33/members/owner1').set({
        userId: 'owner1',
        role: 'owner',
        workspaceId: 'ws33',
      }));
    });

    test('owner can create non-owner member records', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws34/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws34' });
      await db.doc('workspaces/ws34').set({ ownerId: 'owner1', name: 'ws34' });
      await assertSucceeds(db.doc('workspaces/ws34/members/bob').set({
        userId: 'bob',
        role: 'member',
        workspaceId: 'ws34',
      }));
    });

    test('non-member cannot create any member record', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await assertFails(db.doc('workspaces/ws35/members/mallory').set({
        userId: 'mallory',
        role: 'member',
        workspaceId: 'ws35',
      }));
    });
  });

  describe('member role privilege escalation (security)', () => {
    test('admin cannot change a member to owner role', async () => {
      const admin = authedApp('admin1', 'admin@example.com');
      const db = admin.firestore();
      await db.doc('workspaces/ws36/members/admin1').set({ role: 'admin', userId: 'admin1', workspaceId: 'ws36' });
      await db.doc('workspaces/ws36/members/bob').set({ role: 'member', userId: 'bob', workspaceId: 'ws36' });
      await db.doc('workspaces/ws36').set({ ownerId: 'owner1', name: 'ws36' });
      await assertFails(db.doc('workspaces/ws36/members/bob').update({ role: 'owner' }));
    });

    test('manager cannot change a member to admin role', async () => {
      const manager = authedApp('manager1', 'manager@example.com');
      const db = manager.firestore();
      await db.doc('workspaces/ws37/members/manager1').set({ role: 'manager', userId: 'manager1', workspaceId: 'ws37' });
      await db.doc('workspaces/ws37/members/bob').set({ role: 'member', userId: 'bob', workspaceId: 'ws37' });
      await db.doc('workspaces/ws37').set({ ownerId: 'owner1', name: 'ws37' });
      // Manager is not ownerOrAdmin, so cannot update roles at all.
      await assertFails(db.doc('workspaces/ws37/members/bob').update({ role: 'admin' }));
    });

    test('owner can change any member role including owner', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws38/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws38' });
      await db.doc('workspaces/ws38/members/bob').set({ role: 'member', userId: 'bob', workspaceId: 'ws38' });
      await db.doc('workspaces/ws38').set({ ownerId: 'owner1', name: 'ws38' });
      await assertSucceeds(db.doc('workspaces/ws38/members/bob').update({ role: 'owner' }));
    });

    test('non-owner cannot delete an owner member', async () => {
      const admin = authedApp('admin1', 'admin@example.com');
      const db = admin.firestore();
      await db.doc('workspaces/ws39/members/admin1').set({ role: 'admin', userId: 'admin1', workspaceId: 'ws39' });
      await db.doc('workspaces/ws39/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws39' });
      await db.doc('workspaces/ws39').set({ ownerId: 'owner1', name: 'ws39' });
      await assertFails(db.doc('workspaces/ws39/members/owner1').delete());
    });

    test('owner cannot remove themselves if they are the owner', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws40/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws40' });
      await db.doc('workspaces/ws40').set({ ownerId: 'owner1', name: 'ws40' });
      await assertFails(db.doc('workspaces/ws40/members/owner1').delete());
    });
  });

  describe('invitation acceptance hardening (security)', () => {
    test('invited email can accept pending unexpired invitation', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws50/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws50' });
      await db.doc('workspaces/ws50/invitations/inv50').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws50',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      await assertSucceeds(dbBob.doc('workspaces/ws50/invitations/inv50').update({ status: 'accepted' }));
    });

    test('invited email can decline pending unexpired invitation', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws51/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws51' });
      await db.doc('workspaces/ws51/invitations/inv51').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws51',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      await assertSucceeds(dbBob.doc('workspaces/ws51/invitations/inv51').update({ status: 'declined' }));
    });

    test('wrong email cannot accept invitation', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws52/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws52' });
      await db.doc('workspaces/ws52/invitations/inv52').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws52',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      // Mallory (not the invited email) tries to accept Bob's invitation.
      const mallory = authedApp('mallory', 'mallory@example.com');
      const dbMallory = mallory.firestore();
      await assertFails(dbMallory.doc('workspaces/ws52/invitations/inv52').update({ status: 'accepted' }));
    });

    test('expired invitation cannot be accepted', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws53/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws53' });
      await db.doc('workspaces/ws53/invitations/inv53').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws53',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      await assertFails(dbBob.doc('workspaces/ws53/invitations/inv53').update({ status: 'accepted' }));
    });

    test('non-pending invitation cannot be accepted', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws54/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws54' });
      await db.doc('workspaces/ws54/invitations/inv54').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'accepted',
        invitedBy: 'owner1',
        workspaceId: 'ws54',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      // Already accepted; trying to change status again should fail (status must change from pending).
      await assertFails(dbBob.doc('workspaces/ws54/invitations/inv54').update({ status: 'declined' }));
    });

    test('invited user cannot change fields other than status on acceptance', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws55/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws55' });
      await db.doc('workspaces/ws55/invitations/inv55').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws55',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      // Bob tries to change role AND status — affectedKeys would be ['role', 'status'], not hasOnly(['status']).
      await assertFails(dbBob.doc('workspaces/ws55/invitations/inv55').update({
        status: 'accepted',
        role: 'admin',
      }));
    });

    test('invited user cannot set status to invalid value', async () => {
      const owner = authedApp('owner1', 'owner@example.com');
      const db = owner.firestore();
      await db.doc('workspaces/ws56/members/owner1').set({ role: 'owner', userId: 'owner1', workspaceId: 'ws56' });
      await db.doc('workspaces/ws56/invitations/inv56').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        invitedBy: 'owner1',
        workspaceId: 'ws56',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      });

      const bob = authedApp('bob', 'bob@example.com');
      const dbBob = bob.firestore();
      await assertFails(dbBob.doc('workspaces/ws56/invitations/inv56').update({ status: 'archived' }));
    });

    test('non-member cannot create invitations', async () => {
      const mallory = authedApp('mallory', 'mallory@example.com');
      const db = mallory.firestore();
      await assertFails(db.doc('workspaces/ws57/invitations/inv57').set({
        email: 'bob@example.com',
        role: 'member',
        status: 'pending',
        expiresAt: firebase.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
      }));
    });
  });

  describe('task assignee membership requirement (security)', () => {
    test('task create with non-member assignee is rejected', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws60/members/alice').set({ role: 'member', userId: 'alice', workspaceId: 'ws60' });
      await db.doc('workspaces/ws60').set({ ownerId: 'alice', name: 'ws60' });
      // Bob is not a member of ws60.
      await assertFails(db.doc('workspaces/ws60/tasks/t1').set({
        ownerId: 'alice',
        assigneeId: 'bob',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws60',
      }));
    });

    test('task create with member assignee is allowed', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws61/members/alice').set({ role: 'member', userId: 'alice', workspaceId: 'ws61' });
      await db.doc('workspaces/ws61/members/bob').set({ role: 'member', userId: 'bob', workspaceId: 'ws61' });
      await db.doc('workspaces/ws61').set({ ownerId: 'alice', name: 'ws61' });
      await assertSucceeds(db.doc('workspaces/ws61/tasks/t1').set({
        ownerId: 'alice',
        assigneeId: 'bob',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws61',
      }));
    });

    test('task update changing assignee to non-member is rejected', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws62/members/alice').set({ role: 'member', userId: 'alice', workspaceId: 'ws62' });
      await db.doc('workspaces/ws62').set({ ownerId: 'alice', name: 'ws62' });
      await db.doc('workspaces/ws62/tasks/t2').set({
        ownerId: 'alice',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws62',
      });
      // Bob is not a member of ws62.
      await assertFails(db.doc('workspaces/ws62/tasks/t2').update({ assigneeId: 'bob' }));
    });

    test('task update changing assignee to member is allowed', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await db.doc('workspaces/ws63/members/alice').set({ role: 'member', userId: 'alice', workspaceId: 'ws63' });
      await db.doc('workspaces/ws63/members/bob').set({ role: 'member', userId: 'bob', workspaceId: 'ws63' });
      await db.doc('workspaces/ws63').set({ ownerId: 'alice', name: 'ws63' });
      await db.doc('workspaces/ws63/tasks/t3').set({
        ownerId: 'alice',
        title: 'x',
        status: 'todo',
        priority: 'medium',
        category: 'personal',
        workspaceId: 'ws63',
      });
      await assertSucceeds(db.doc('workspaces/ws63/tasks/t3').update({ assigneeId: 'bob' }));
    });
  });

  describe('default deny', () => {
    test('unknown collection is denied', async () => {
      const alice = authedApp('alice', 'alice@example.com');
      const db = alice.firestore();
      await assertFails(db.doc('nonexistent/doc').get());
    });

    test('unauthenticated access is denied', async () => {
      const db = initializeTestApp({ projectId: PROJECT_ID }).firestore();
      await assertFails(db.doc('users/test').get());
    });
  });
});
