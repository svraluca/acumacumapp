import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

export const sendScheduledNotifications = functions.pubsub
  .schedule('0 10,20 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const message = {
        notification: {
          title: 'Scheduled Notification',
          body: 'This is a scheduled notification'
        },
        topic: 'all_users'
      };

      await admin.messaging().send(message);
      console.log('Notification sent successfully');
      return null;
      
    } catch (error) {
      console.error('Error sending notification:', error);
      throw error;
    }
  });
