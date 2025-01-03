import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi{

  Future<void> initNotifications() async{
    final _firebaseMessaging = FirebaseMessaging.instance;
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print('Token: $fcmToken');

  }
}