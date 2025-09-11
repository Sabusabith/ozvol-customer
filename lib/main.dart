import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print("Foreground message received: ${message.notification!.title}");
    }
  });
  runApp(MyApp());
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
