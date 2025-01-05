import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

class FirebaseApi{
  // final _firebaseMessaging = FirebaseMessaging.instance;
  Future<void> initNotifications() async{

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
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