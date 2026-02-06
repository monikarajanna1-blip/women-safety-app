import 'dart:isolate';
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackingBackgroundHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSub;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print("📡 BACKGROUND TRACKING STARTED");

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10, // meters
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) async {
      // ❌ Ignore bad GPS fixes
      if (pos.accuracy > 30) {
        print("⚠️ Ignored inaccurate fix: ${pos.accuracy}");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print(
        "📍 REAL GPS: ${pos.latitude}, ${pos.longitude} (acc=${pos.accuracy})",
      );

      await FirebaseFirestore.instance
          .collection("tracking")
          .doc(user.uid)
          .collection("locations")
          .add({
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "accuracy": pos.accuracy,
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("✅ Location saved");
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {}

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    _positionSub?.cancel();
    print("🛑 BACKGROUND TRACKING STOPPED");
  }
}

@pragma("vm:entry-point")
void trackingCallback() {
  FlutterForegroundTask.setTaskHandler(
    TrackingBackgroundHandler());
}
