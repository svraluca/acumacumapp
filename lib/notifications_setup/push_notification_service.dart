// import 'dart:developer';

// import 'package:acumacum/model/notification_data.dart';
import 'package:acumacum/notifications_setup/logging/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tzd;

final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

class PushNotificationService {
  final _logger = getLogger('PushNotificationService');
  late FirebaseMessaging _messaging;

  // Make this a singleton class.

  PushNotificationService._internal() {
    _messaging = FirebaseMessaging.instance;
  }

  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        _logger.w("payload: $payload");
        _logger.i('onDidReceiveLocalNotification');
      },
    );

    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    // tzd.initializeTimeZones();
    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> startListeningToNotification() async {
    final bool permission = await _getNotificationPermission();
    if (permission) {
      _logger.i(await _messaging.getToken());

      _appIsMinimizedNotTerminated();
      _appIsOpened();
      _backgroundNotificationHandler();
    } else {
      _logger.w('Permission denied');
    }
  }

  Future<bool> _getNotificationPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  void _backgroundNotificationHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _appIsMinimizedNotTerminated() async {
    // RemoteMessage? remoteMessage = await _messaging.getInitialMessage();
    // if (remoteMessage != null) {
    //   _logger.i('Notification received when app was terminated.');
    //   _logger.wtf(remoteMessage.toMap());
    //   // final NotificationData notificationData = NotificationData.fromJson(remoteMessage.data);
    //   // _showLocalNotification(notificationData);
    //   return; // Avoid listening to `onMessageOpenedApp` if a notification is already handled.
    // }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _logger.i('Notification received when app is opened but minimized.');
      _logger.i(message.toMap());
      // final NotificationData notificationData = NotificationData.fromJson(message.data);
      // _showLocalNotification(notificationData);
    });
  }

  Future<void> _appIsOpened() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _logger.i('notification is received when app is opened');
      // final NotificationData notificationData = NotificationData.fromJson(message.data);
      _logger.i(message.notification?.title);
      _logger.i(message.notification?.body);
      _logger.i(message.toMap());
      //_showLocalNotification(message);
    });
  }

  Future<String?> getAndroidToken() async {
    return await _messaging.getToken();
  }

  Future<String?> getIosToken() async {
    return await _messaging.getAPNSToken();
  }

  Future<void> deleteFCMToken() async {
    try {
      _logger.i('Deleting FCM token...');
      await _messaging.deleteToken();
      _logger.i('FCM token deleted successfully.');
    } catch (e) {
      _logger.e('Error deleting FCM token: $e');
    }
  }

  void onTokenRefresh() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      _logger.i('Current user id: $currentUserId');
      await FirebaseFirestore.instance.collection('Users').doc(currentUserId).update({
        'fcmToken': await getAndroidToken(),
      });
      _logger.i('FCM Token updated: ${await getAndroidToken()}');
    }
    _messaging.onTokenRefresh.listen((fcmToken) async {
      _logger.i('Token refreshed');
      _logger.i(fcmToken);
      final token = fcmToken;

      if (currentUserId != null) {
        await FirebaseFirestore.instance.collection('Users').doc(currentUserId).update({
          'fcmToken': token,
        });
        _logger.i('FCM Token updated: $token');
      }
    }).onError((err) {
      // Error getting token.
    });
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final logger = getLogger('PuchNotificationServiceBackground');
  logger.i("Handling a background message: ${message.messageId}");
  // NotificationData notificationData = NotificationData.fromJson(message.data);
  // _showLocalNotification(notificationData);
}

// Future<void> _showLocalNotification(RemoteMessage? message) async {
//   if (message == null) {
//     getLogger('PushNotificationService').e('Message is null');
//     return;
//   }
//   // iOS specific notification details (DarwinNotificationDetails for iOS/macOS)
//   const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
//     presentAlert: true, // Show alert when app is in foreground
//     presentBadge: true, // Show app icon badge number
//     presentSound: true, // Play sound
//   );

//   const NotificationDetails platformChannelSpecifics = NotificationDetails(
//     iOS: iOSPlatformChannelSpecifics,
//   );

//   _localNotificationsPlugin
//       .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>(
//           // This is required to show notification on iOS
//           )
//       ?.requestPermissions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );

//   await _localNotificationsPlugin.show(
//     0,
//     message.notification?.title,
//     message.notification?.body,
//     platformChannelSpecifics,
//     payload: message.data.toString(),
//   );
// }
