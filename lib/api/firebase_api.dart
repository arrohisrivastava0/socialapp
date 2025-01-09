// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'dart:developer';
//
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// import '../firebase_options.dart';
//
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await FirebaseApi.instance.setupFlutterNotification();
//   await FirebaseApi.instance.showFlutterNotification(message);
// }
//
//
// class FirebaseApi{
//
//   FirebaseApi._();
//   static final FirebaseApi instance = FirebaseApi._();
//   final _firebaseMessaging = FirebaseMessaging.instance;
//   final _localNotifications = FlutterLocalNotificationsPlugin();
//   bool _isLocalNotiInit = false;
//
//   Future<void> requestPermission() async{
//     final settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       provisional: false,
//       announcement: false,
//       carPlay: false,
//       criticalAlert: false
//     );
//
//     print("Permission status: ${settings.authorizationStatus}");
//   }
//
//   Future<void> setupFlutterNotification() async{
//     if(_isLocalNotiInit) return;
//     const channel = AndroidNotificationChannel(
//         'high_importance_channel',
//         'High Importance Notifications',
//       description: 'This channel is used for high importance notifications.',
//       importance: Importance.high
//     );
//
//     await _localNotifications.resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//
//     final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     final initializationSettingsIos= DarwinInitializationSettings(
//
//     );
//
//     final initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIos
//     );
//
//     await _localNotifications.initialize(
//         initializationSettings,
//       onDidReceiveNotificationResponse: (details){
//
//       }
//     );
//
//     _isLocalNotiInit=true;
//   }
//
//   Future<void> showFlutterNotification(RemoteMessage message) async{
//     RemoteNotification? notification = message.notification;
//     AndroidNotification? android = message.notification?.android;
//
//     // if (notification != null && android != null) {
//     //   await _localNotifications.show(
//     //     notification.hashCode,
//     //     notification.title,
//     //     notification.body,
//     //     NotificationDetails(
//     //       android: AndroidNotificationDetails(
//     //         channel.id,
//     //         channel.name,
//     //         channelDescription: channel.description,
//     //         // TODO add a proper drawable resource to android, for now using
//     //         //      one that already exists in example app.
//     //         icon: 'launch_background',
//     //       ),
//     //
//     //       iOS: const DarwinNotificationDetails(
//     //         presentAlert: true,
//     //         presentBadge: true,
//     //         presentSound: true
//     //       )
//     //     ),
//     //     payload: message.data.toString(),
//     //   );
//     // }
//   }
//
//   Future<void> _setupMessageHandlers() async{
//     FirebaseMessaging.onMessage.listen((message){
//       showFlutterNotification(message);
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroudMessage);
//
//     final initialMessage = await _firebaseMessaging.getInitialMessage();
//     if(initialMessage!=null){
//       _handleBackgroudMessage(initialMessage);
//     }
//
//   }
//
//   void _handleBackgroudMessage(RemoteMessage message){
//     final data = message.data;
//     final type = data['type'];
//
//     switch (type) {
//       case 'like':
//       // Navigate to the post details
//         print("Post liked: ${data['postId']}");
//         break;
//
//       case 'comment':
//       // Navigate to the comments section
//         print("Comment on post: ${data['postId']}");
//         break;
//
//       case 'connection':
//       // Show connection request details
//         print("New connection request!");
//         break;
//
//       default:
//         print("Unhandled notification type: $type");
//     }
//   }
//
//
//   Future<void> initNotifications() async{
//
//     await requestPermission();
//     await _setupMessageHandlers();
//     // try {
//     //   String? fcmToken = await _firebaseMessaging.getToken();
//     //   if (fcmToken != null) {
//     //     log('Token: $fcmToken');
//     //     print('Token: $fcmToken');
//     //   } else {
//     //     log('FCM token is null');
//     //     print('FCM token is null');
//     //   }
//     // } catch (e) {
//     //   log('Error fetching token: $e');
//     //   print('Error fetching token: $e');
//     // }
//
//   }
// }

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class FirebaseApi {
  FirebaseApi._();
  static final FirebaseApi instance = FirebaseApi._();

  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isLocalNotiInit = false;

  /// Request Notification Permissions
  Future<void> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log("Permission status: ${settings.authorizationStatus}");
  }

  /// Setup Local Notifications
  Future<void> setupFlutterNotification() async {
    if (_isLocalNotiInit) return;

    const channel = AndroidNotificationChannel(
      'high_importance_channel', // ID
      'High Importance Notifications', // Name
      description: 'This channel is used for high importance notifications.', // Description
      importance: Importance.high,
    );

    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    _isLocalNotiInit = true;
  }

  /// Show Notification
  Future<void> showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Channel ID
            'High Importance Notifications', // Channel Name
            channelDescription: 'This channel is used for high importance notifications.',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle Background Message
  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(showFlutterNotification);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Navigate on Notification Tap
  void _handleBackgroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'likePost':
        log("Post liked: ${data['postId']}");
        break;

      case 'comment':
        log("Comment on post: ${data['postId']}");
        break;

      case 'likeComment':
        log("Your comment was liked!");
        break;

      default:
        log("Unhandled notification type: $type");
    }
  }

  /// Handle Notification Tap from Local Notification
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      log("Notification tapped: $payload");
      // Handle navigation based on payload
    }
  }

  /// Initialize Notifications
  Future<void> initNotifications() async {
    await requestPermission();
    await setupFlutterNotification();
    await _setupMessageHandlers();
  }
}
