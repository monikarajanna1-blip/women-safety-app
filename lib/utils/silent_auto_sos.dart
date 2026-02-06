import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SilentAutoSOS {
  static Future<void> trigger({bool background = false}) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("guardian_alerts").add({
      "user": user.uid,
      "timestamp": DateTime.now(),
      "type": "warning",
      "message": "Lyra detected unusual conditions.",
    });
  }

  static Future<void> sendFullSOS() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("sos_alerts").add({
      "user": user.uid,
      "timestamp": DateTime.now(),
      "type": "emergency",
      "status": "active",
    });
  }
}
