import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

export {
  createInvitation,
  acceptInvitation,
  changeMemberRole,
  sendTaskAssignmentNotification,
  cleanExpiredInvitations,
} from './invitations';
export { sendTaskReminderNotifications as sendReminders } from './reminders';
