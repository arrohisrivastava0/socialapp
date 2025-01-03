import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/api/firebase_api.dart';
import 'package:socialapp/auth/auth_page.dart';
import 'package:socialapp/theme/dark_mode.dart';
import 'package:socialapp/theme/light_mode.dart';

import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}