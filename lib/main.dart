// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:socialapp/api/firebase_api.dart';
// import 'package:socialapp/auth/auth_page.dart';
// import 'package:socialapp/theme/dark_mode.dart';
// import 'package:socialapp/theme/light_mode.dart';
//
// import 'firebase_options.dart';
//
// void main() async{
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const AuthPage(),
//       theme: lightMode,
//       darkTheme: darkMode,
//     );
//   }
// }

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

  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && message.data.containsKey('screen')) {
        navigateToScreen(message.data['screen'], message.data);
      }
    });

    // Handle foreground notifications
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('Foreground message received: ${message.notification?.title}');
    //   if (message.data.containsKey('screen')) {
    //     String screen = message.data['screen'];
    //     navigateToScreen(screen, message.data);
    //   }
    // });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
      if (message.data.containsKey('screen')) {
        String screen = message.data['screen'];
        navigateToScreen(screen, message.data);
      }
    });
  }

  void navigateToScreen(String screen, Map<String, dynamic> data) {

    if (screen == 'Post' && data['uid'] != null){
      navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => SeparatePostPage(postId: data['uid'],),
          ),
        );
      }else {
      print('Invalid screen or data');
    }
    // Add more screens as needed
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const AuthPage(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}
