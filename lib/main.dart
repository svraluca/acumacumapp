import 'package:acumacum/notifications_setup/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  PushNotificationService messagingService = PushNotificationService();
  await messagingService.initializeLocalNotifications();
  await messagingService.startListeningToNotification();
  messagingService.onTokenRefresh();

  // Initialize Stripe
  Stripe.publishableKey = 'pk_test_VWRoWcjr7zIDL4mhxbVIYRv2';
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'acumacum',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GetstartedScreen(),
    );
  }
}
