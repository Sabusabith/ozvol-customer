import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// =======================
// BACKGROUND HANDLER
// =======================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
    "📩 Background: ${message.notification?.title} - ${message.notification?.body}",
  );
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupFCM() async {
  // 🔹 Ask for notification permission once
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.subscribeToTopic("allCustomers");

  // 🔹 Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print(
      "📩 Foreground: ${message.notification?.title} - ${message.notification?.body}",
    );

    if (message.notification != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'default_channel', // id
            'General Notifications', // name
            channelDescription:
                'This channel is used for general notifications.',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title,
        message.notification!.body,
        platformDetails,
      );
    }
  });

  // 🔹 When app opened from notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📩 Notification clicked: ${message.notification?.title}");
    // TODO: Navigate to specific screen if needed
  });
}

Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔹 Background handler must be registered before runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await setupLocalNotifications();
  await setupFCM();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: CustomerLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
