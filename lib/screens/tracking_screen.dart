import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/tracking_background_service.dart';

// Map imports
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => TrackingScreenState();
}

class TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  bool isTracking = false;

  @override
  void initState() {
    super.initState();
    _initForegroundService();
  }


  // ------------------------------------------------------------
  // FOREGROUND SERVICE INITIALIZATION
  // ------------------------------------------------------------
  Future<void> _initForegroundService() async {
     FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tracking_channel',
        channelName: 'Live Tracking',
        channelDescription: 'Lyra is tracking your location',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 30000, // 30 sec
        autoRunOnBoot: true,
        allowWakeLock: true,
      ),
    );
  }

  // ------------------------------------------------------------
  // START TRACKING
  // ------------------------------------------------------------
  Future<void> _startTracking() async {
    print("▶️ START TRACKING");

    // Permission check
    if (!await Permission.locationAlways.isGranted) {
      await Permission.locationAlways.request();
    }

    if (!await Permission.locationAlways.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location permission required to start tracking")),
      );
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Lyra Tracking Active',
      notificationText: 'Your live location is being shared.',
      callback: trackingCallback,
    );

    setState(() => isTracking = true);
    await FirebaseFirestore.instance.collection("tracking_events").add({
  "userId": FirebaseAuth.instance.currentUser!.uid,
  "type": "started",
  "timestamp": FieldValue.serverTimestamp(),
});

  }

  // ------------------------------------------------------------
  // STOP TRACKING
  // ------------------------------------------------------------
  Future<void> _stopTracking() async {
    print("⏹ STOP TRACKING");

    await FlutterForegroundTask.stopService();
    setState(() => isTracking = false);
  }

  // ------------------------------------------------------------
  // GUARDIAN COUNT STREAM
  // ------------------------------------------------------------
  Stream<int> _guardianCountStream() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('guardians')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ------------------------------------------------------------
  // LIVE MAP
  // ------------------------------------------------------------
  Widget _buildTrackingMap() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tracking')
          .doc(userId)
          .collection('locations')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(
              child: Text("No tracking data yet...",
                  style: TextStyle(color: Colors.white70)));
        }

        final points = docs.map((d) {
          return LatLng(d['latitude'], d['longitude']);
        }).toList();

        return FlutterMap(
          options: MapOptions(
            initialCenter: points.last,
            initialZoom: 16,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.lyra.app",
            ),
            PolylineLayer(polylines: [
              Polyline(
                points: points,
                color: Colors.deepPurpleAccent,
                strokeWidth: 4,
              )
            ]),
            MarkerLayer(
              markers: [
                Marker(
                  point: points.last,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_pin,
                      size: 40, color: Colors.red),
                )
              ],
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UI BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        title: const Text("Live Tracking"),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.3),
                ),
              ),
              child: isTracking ? _buildTrackingMap() : _idleUI(),
            ),
          ),

          // Guardian count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Colors.white),
                  const SizedBox(width: 10),
                  StreamBuilder<int>(
                    stream: _guardianCountStream(),
                    builder: (_, snap) {
                      return Text(
                        "Guardians: ${snap.data ?? 0}",
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Start / Stop
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: ElevatedButton(
              onPressed: () {
                isTracking ? _stopTracking() : _startTracking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isTracking ? Colors.red : const Color(0xFF8B5CF6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: Text(
                isTracking ? "Stop Tracking" : "Start Tracking",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // IDLE UI
  // ------------------------------------------------------------
  Widget _idleUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.location_on, size: 50, color: Color(0xFFB388FF)),
        SizedBox(height: 10),
        Text("Tracking not started",
            style: TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    );
  }
}
