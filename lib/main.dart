import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/api/firebase_api.dart';
import 'package:socialapp/auth/auth_page.dart';
import 'package:socialapp/pages/separate_post_page.dart';
import 'package:socialapp/theme/dark_mode.dart';
import 'package:socialapp/theme/light_mode.dart';

import 'firebase_options.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase notifications
    await FirebaseApi.instance.initNotifications();
    String? token = await FirebaseMessaging.instance.getToken();
    print("Token is: $token");

    // Handle the app being launched from a terminated state via a notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final screen = data['screen'] ?? '';
  final postId = data['uid'] ?? '';

  if (screen == 'Post' && postId.isNotEmpty) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => SeparatePostPage(postId: postId),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // void navigateToScreen(String screen, Map<String, dynamic> data) {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: AuthPage(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}
