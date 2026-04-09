import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init(String userId) async {
    try {
      // 1. Request permission for notifications
      NotificationSettings settings = await _fcm.requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Get the device token
        String? token = await _fcm.getToken();
        if (token != null) {
          // 3. Save the token to the user's Firestore document
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'fcmToken': token,
          });
        }
      }

      // 4. Setup foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          // A real app would use flutter_local_notifications to show a heads-up banner here
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification}');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Failed to initialize notifications: $e");
      }
    }
  }
}
