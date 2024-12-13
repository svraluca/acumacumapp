const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatNotification = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap) => {
        const notification = snap.data();

        const message = {
            token: notification.token,
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: notification.data,
            android: {
                priority: "high",
                notification: {
                    channelId: "chat_channel_id",
                    sound: "default",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
        };

        try {
            const response = await admin.messaging().send(message);
            console.log("Successfully sent notification:", response);

            // Delete the notification document after sending
            await snap.ref.delete();

            return {success: true};
        } catch (error) {
            console.error("Error sending notification:", error);
            return {error};
        }
    });
