import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lyra_new/utils/sos_manager.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'incoming_call_screen.dart';

import '../services/ai_model_service.dart';


class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  // ================= AI =================
  late AIModelService aiService;
  bool _aiReady = false;

  double timeFeature = 0.0;
  double motionFeature = 0.0;
  double noiseFeature = 0.0;
  double locationFeature = 0.2;
  double totalRisk = 0.0;
  bool aiSosSent = false;
  int highRiskCounter = 0;



  final List<double> riskSequence = [];

  // ================= MOTION =================
  late StreamSubscription _motionSub;
  final List<double> motionWindow = [];

  // ================= NOISE =================
  NoiseMeter? _noiseMeter;
  StreamSubscription? _noiseSub;
  final List<double> noiseWindow = [];

  // ================= SIREN =================
  final AudioPlayer _sirenPlayer = AudioPlayer();
  bool sirenPlaying = false; 

  @override
  void initState() {
    super.initState();
    _initAI();
  }

  Future<void> _initAI() async {
    aiService = AIModelService();
    await aiService.loadANN();

    _extractTimeFeature();
    _listenMotion();
    await _listenNoise();
    _fetchLocationRisk();

    setState(() => _aiReady = true);
  }

  // ================= TIME =================
  void _extractTimeFeature() {
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 5) {
      timeFeature = 0.8;
    } else if (hour >= 18) {
      timeFeature = 0.5;
    } else {
      timeFeature = 0.2;
    }
  }

  // ================= MOTION =================
  void _listenMotion() {
    _motionSub = accelerometerEvents.listen((event) {
      final magnitude = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z,
      );

      final delta = (magnitude - 9.8).abs();

      motionWindow.add(delta);
      if (motionWindow.length > 5) motionWindow.removeAt(0);

      motionFeature =
          (motionWindow.reduce((a, b) => a + b) /
                  motionWindow.length)
              .clamp(0.0, 1.5) /
              1.5;

      _runAI();
    });
  }

  // ================= NOISE =================
  Future<void> _listenNoise() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _noiseMeter = NoiseMeter();
    _noiseSub = _noiseMeter!.noise.listen((noise) {
      noiseWindow.add(noise.meanDecibel);
      if (noiseWindow.length > 5) noiseWindow.removeAt(0);

      noiseFeature =
          ((noiseWindow.reduce((a, b) => a + b) /
                      noiseWindow.length) -
                  30)
              .clamp(0.0, 40.0) /
              40.0;

      _runAI();
    });
  }

  // ================= LOCATION =================
  Future<void> _fetchLocationRisk() async {
    try {
      LocationPermission perm =
          await Geolocator.requestPermission();

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _runAI();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final snap = await FirebaseFirestore.instance
          .collection("danger_zones")
          .get();

      double highest = 0.2;

      for (var doc in snap.docs) {
        final d = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          doc["latitude"],
          doc["longitude"],
        );

        if (d < 300) {
          highest =
              max(highest, doc["risk_level"].toDouble());
        }
      }

      locationFeature = highest;
      _runAI();
    } catch (_) {
      _runAI();
    }
  }

  // ================= AI =================
  void _runAI() {
    if (!mounted || !_aiReady || !aiService.isLoaded) return;
    
debugPrint(
  "AI INPUTS → time:$timeFeature motion:$motionFeature noise:$noiseFeature location:$locationFeature"
);

    final annRisk = aiService.runANN([
      timeFeature,
      motionFeature,
      noiseFeature,
      locationFeature,
    ]);

    riskSequence.add(annRisk);
    if (riskSequence.length > 5) {
      riskSequence.removeAt(0);
    }

    totalRisk =
        riskSequence.reduce((a, b) => a + b) /
            riskSequence.length;
    debugPrint("risk=$totalRisk counter=$highRiskCounter");
        
if (totalRisk >= 0.6) {
  highRiskCounter++;
} else {
  highRiskCounter = 0;
}

if (highRiskCounter >= 5 && !aiSosSent) {
  aiSosSent = true;
  debugPrint("AI SOS TRIGGERED (sustained risk)");

  SosManager.triggerSOS(
    source: "ai",
    risk: totalRisk,
  );
}
    setState(() {});
  }
  
  // ================= SIREN =================
  Future<void> _toggleSiren() async {
    if (sirenPlaying) {
      await _sirenPlayer.stop();
    } else {
      await _sirenPlayer.play(
        AssetSource('audio/sos_alerts.mp3'),
        volume: 1.0,
      );
    }

    setState(() {
      sirenPlaying = !sirenPlaying;
    });
  }


  @override
  void dispose() {
    _motionSub.cancel();
    _noiseSub?.cancel();
    aiService.dispose();
    _sirenPlayer.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (!_aiReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Safety Prediction"),
      ),

      backgroundColor: const Color(0xFFF3ECFF),

      body: Column(
        children: [
          const SizedBox(height: 24),

          // 🔵 RISK RING
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: totalRisk,
                  strokeWidth: 18,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(
                    totalRisk < 0.4
                        ? Colors.green
                        : totalRisk < 0.7
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                Text(
                  "${(totalRisk * 100).toInt()}%",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text("Current Risk Level"),

          const SizedBox(height: 24),

          // 🔵 INFO CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _InfoRow(
                      icon: Icons.access_time,
                      label: "Time",
                      value: "Daytime Safe",
                    ),
                    _InfoRow(
                      icon: Icons.directions_run,
                      label: "Motion",
                      value: "High Movement",
                    ),
                    _InfoRow(
                      icon: Icons.volume_up,
                      label: "Audio",
                      value: "Very Loud",
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
             onPressed: () {
              SosManager.triggerSOS(
                source: "ai",
                risk: totalRisk,
              );
            },
                        child: const Text(
              "⚠ Simulate Danger",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),

      // 🔵 BOTTOM BUTTONS
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Row(
          children: [
            _ActionButton(
              icon: Icons.phone,
              label: "Fake Call",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncomingCallScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.campaign,
              label: "Siren",
              onTap: _toggleSiren,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.mic,
              label: "Voice SOS",
              onTap: () {
                SosManager.triggerSOS(
      source: "voice",
      risk: totalRisk,
    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ================= UI HELPERS =================
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}