// lib/screens/sos_screen.dart

import 'package:flutter/material.dart';
import 'package:lyra_new/utils/sos_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sending = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendSos() async {
    setState(() => _sending = true);

    try {
      // 1️⃣ Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("User not logged in.");
        setState(() => _sending = false);
        return;
      }

      // 2️⃣ Request location permission
      if (!await Permission.location.request().isGranted) {
        _showError("Location permission denied");
        setState(() => _sending = false);
        return;
      }

      // 3️⃣ Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;

      // 4️⃣ Play SOS alarm
     // await _audioPlayer.play(AssetSource('audio/sos_alert.mp3'));

      // 5️⃣ Save alert to Firestore
      await SosManager.triggerSOS(source: "manual");


      // 6️⃣ Show success popup
      _showSuccessPopup(lat, lon);

    } catch (e) {
      _showError(e.toString());
    }

    setState(() => _sending = false);
  }

  // 🔥 SUCCESS POP-UP
  void _showSuccessPopup(double lat, double lon) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "SOS Sent Successfully!",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Your SOS alert has been sent.\n\n"
            "📍 Latitude: $lat\n"
            "📍 Longitude: $lon\n\n"
            "Help is on the way!",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ❌ ERROR POP-UP
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Error",
            style: TextStyle(color: Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade400,
      appBar: AppBar(
        title: const Text('SOS'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Tap to send SOS',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 30),

            // 🔘 SOS BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _sending ? null : _sendSos,
              child: _sending
                  ? const CircularProgressIndicator(color: Colors.red)
                  : const Text('SEND SOS', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}




