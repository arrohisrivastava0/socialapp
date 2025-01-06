import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi{


  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isLocalNotiInit = false;

  Future<void> requestPermission() async{
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false
    );

    print("Permission status: ${settings.authorizationStatus}");
  }

  Future<void> setupFlutterNotification() async{
    if(_isLocalNotiInit) return;
    const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
      description: 'This channel is used for high importance notifications.',
      importance: Importance.high
    );

    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettingsIos= DarwinInitializationSettings(

    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIos
    );

    await _localNotifications.initialize(
        initializationSettings,
      onDidReceiveNotificationResponse: (details){

      }
    );

    _isLocalNotiInit=true;
  }




  Future<void> initNotifications() async{
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        log('Token: $fcmToken');
        print('Token: $fcmToken');
      } else {
        log('FCM token is null');
        print('FCM token is null');
      }
    } catch (e) {
      log('Error fetching token: $e');
      print('Error fetching token: $e');
    }

  }
}