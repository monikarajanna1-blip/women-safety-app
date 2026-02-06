import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static Future<void> saveToken(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        print("⚠️ FCM token is null");
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ FCM token saved to Firestore");
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }
}
