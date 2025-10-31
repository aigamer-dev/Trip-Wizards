import * as functions from 'firebase-functions';
import {sendTargetedNotificationHandler} from './notifications/sendTargetedNotification';

export const sendTargetedNotification = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB',
  })
  .https.onCall(sendTargetedNotificationHandler);
