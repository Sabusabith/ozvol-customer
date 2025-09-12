import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> setupFCM() async {
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.subscribeToTopic("allCustomers");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print(
      "📩 Foreground: ${message.notification?.title} - ${message.notification?.body}",
    );

    if (message.notification != null) {
      // Show local notification
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
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

  await setupLocalNotifications(); // ✅ init local notifications
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
