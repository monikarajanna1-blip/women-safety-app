import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class SosManager {
  static Future<void> triggerSOS({
    required String source, // manual | voice | ai
    double? risk,
    String? detectedPhrase,
    String? audioUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double latitude = 0.0;
    double longitude = 0.0;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = pos.latitude;
      longitude = pos.longitude;
    } catch (_) {}

    await FirebaseFirestore.instance.collection("sos_alerts").add({
      "userId": user.uid,
      "source": source,
      "risk": risk,
      "detectedPhrase": detectedPhrase,
      "audioUrl": audioUrl,
      "latitude": latitude,
      "longitude": longitude,
      "timestamp": FieldValue.serverTimestamp(),
      "status": "active",
    });
  }
}
