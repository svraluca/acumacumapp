import 'dart:io';

import 'package:acumacum/notifications_setup/logging/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> startListeningToNotification() async {
    final bool permission = await _getNotificationPermission();
    if (permission) {
      if (kIsWeb) {
        _logger.i(await _messaging.getToken(
            vapidKey: 'BHfsvfBkUMmysePtLIXAKA0bOwvFMNmklr0KBnq4-Xr-0LIGpxuymP-JvdM8hohotAit4CNMAFu2enT5FeCR4hg'));
      } else {
        if (Platform.isIOS) {
          _logger.i(await _messaging.getAPNSToken());
        }
        _logger.i(await _messaging.getToken());
      }
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
    RemoteMessage? remoteMessage = await _messaging.getInitialMessage();
    if (remoteMessage == null) {
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _logger.i('notification is received when app is opened and not terminated');
        _logger.i(message.notification?.title);
        _logger.i(message.notification?.body);
      });
    }
    if (remoteMessage != null) {
      _showLocalNotification(remoteMessage);
    }
  }

  Future<void> _appIsOpened() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _logger.i('notification is received when app is opened');
      _logger.i(message.notification?.title);
      _logger.i(message.notification?.body);
      _showLocalNotification(message);
    });
  }

  Future<String?> getAndroidToken() async {
    return await _messaging.getToken();
  }

  Future<String?> getIosToken() async {
    return await _messaging.getAPNSToken();
  }

  void onTokenRefresh() {
    _messaging.onTokenRefresh.listen((fcmToken) async {
      _logger.i('Token refreshed');
      _logger.i(fcmToken);
      final token = Platform.isIOS ? await getIosToken() : await getAndroidToken();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (token != null && currentUserId != null) {
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
  message.data.forEach((key, value) {
    logger.i('$key: $value');
  });
  _showLocalNotification(message);
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  if (message.data['id'].toString().isEmpty || message.data['sender'].toString().isEmpty) {
    return;
  }
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'holedo_channel_id',
    'hole_do_channel_name',
    channelDescription: 'holedo_channel_description',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  // iOS specific notification details (DarwinNotificationDetails for iOS/macOS)
  const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
    presentAlert: true, // Show alert when app is in foreground
    presentBadge: true, // Show app icon badge number
    presentSound: true, // Play sound
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await _localNotificationsPlugin.show(
    message.data['id'] ?? 0,
    message.data['sender_display_name'] ?? '',
    message.data['content_body'] ?? '',
    platformChannelSpecifics,
    // payload: message.data['your_payload_key'], // Use your payload key if needed
  );
}
